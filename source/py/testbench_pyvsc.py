# **************************************************************************
#
#  Author      : See AUTHORS
#  Project     : cocotb-BSHL
#  Description : testbench with pyvsc
#  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
#
#  *****************************************************************************

from cocotb.triggers import Join, Combine
from pyuvm import *
import random
import cocotb
import pyuvm
import vsc
import asyncio
import sys
from pathlib import Path
sys.path.append(str(Path("..").resolve()))
from tinyalu_utils import TinyAluBfm, Ops, alu_prediction
import ctypes
import os



# users should define the following simulation file path accordingly
current_dir = Path.cwd()
example_dir = current_dir.parent.parent / 'simulation' /'example'
subdir1 = 'sim_build'
subdir2 = 'xcelium.d'
subdir3 = 'run.d'
filename = 'librun.so'
file_path = os.path.join(example_dir, subdir1, subdir2, subdir3, filename)


lib = ctypes.CDLL(file_path)

DATA_WIDTH = 3

class PyTranDesc(ctypes.Structure):
    _fields_ = [
        ("name", ctypes.c_char_p),
        ("rdnwr", ctypes.c_int),
        ("addr", ctypes.c_uint32),
        ("data0", ctypes.c_uint32),
        ("data1", ctypes.c_uint32),
        ("data2", ctypes.c_uint32),
        ("data3", ctypes.c_uint32),
        ("status", ctypes.c_int)
    ]

lib.Recv_Result_from_S.argtypes = [ctypes.POINTER(PyTranDesc), ctypes.POINTER(ctypes.c_bool)]
lib.Recv_Result_from_S.restype = None

desc = PyTranDesc()
empty = ctypes.c_bool(False)


class AluSeqItem(uvm_sequence_item):

    def __init__(self, name, aa, bb, op):
        super().__init__(name)
        self.a = aa
        self.b = bb
        self.op = Ops(op)

    def randomize_operands(self):
        self.a = random.randint(0, 2**DATA_WIDTH-1)
        self.b = random.randint(0, 2**DATA_WIDTH-1)

    def randomize(self):
        self.randomize_operands()
        self.op = random.choice(list(Ops))

    def __eq__(self, other):
        same = self.a == other.a and self.b == other.b and self.op == other.op
        return same

    def __str__(self):
        return f"{self.get_name()} : A: 0x{self.a:02x} \
        OP: {self.op.name} ({self.op.value}) B: 0x{self.b:02x}"


class RandomSeq(uvm_sequence):
    async def body(self):
        for op in list(Ops):
            cmd_tr = AluSeqItem("cmd_tr", None, None, op)
            await self.start_item(cmd_tr)
            cmd_tr.randomize_operands()
            await self.finish_item(cmd_tr)
            # print("RandomSeq", f"Generated item: {cmd_tr}")


class MaxSeq(uvm_sequence):
    async def body(self):
        for op in list(Ops):
            cmd_tr = AluSeqItem("cmd_tr", 0xffffffff, 0xffffffff, op)
            await self.start_item(cmd_tr)
            await self.finish_item(cmd_tr)
            # print("MaxSeq", f"Generated item: {cmd_tr}")

class TestAllSeq(uvm_sequence):

    async def body(self):
        seqr = ConfigDB().get(None, "", "SEQR")
        random = RandomSeq("random")
        max = MaxSeq("max")
        await random.start(seqr)
        await cocotb.triggers.Timer(10, units='ns')
        await max.start(seqr)


class TestAllForkSeq(uvm_sequence):

    async def body(self):
        seqr = ConfigDB().get(None, "", "SEQR")
        random = RandomSeq("random")
        max = MaxSeq("max")
        random_task = cocotb.fork(random.start(seqr))
        max_task = cocotb.fork(max.start(seqr))
        await Combine(Join(random_task), Join(max_task))


class OpSeq(uvm_sequence):
    def __init__(self, name, aa, bb, op):
        super().__init__(name)
        self.aa = aa
        self.bb = bb
        self.op = Ops(op)

    async def body(self):
        seq_item = AluSeqItem("seq_item", self.aa, self.bb,
                              self.op)
        await self.start_item(seq_item)
        await self.finish_item(seq_item)
        self.result = seq_item.result


async def do_add(seqr, aa, bb):
    seq = OpSeq("seq", aa, bb, Ops.ADD)
    await seq.start(seqr)
    return seq.result


async def do_and(seqr, aa, bb):
    seq = OpSeq("seq", aa, bb, Ops.AND)
    await seq.start(seqr)
    return seq.result


async def do_xor(seqr, aa, bb):
    seq = OpSeq("seq", aa, bb, Ops.XOR)
    await seq.start(seqr)
    return seq.result


async def do_mul(seqr, aa, bb):
    seq = OpSeq("seq", aa, bb, Ops.MUL)
    await seq.start(seqr)
    return seq.result


class FibonacciSeq(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.seqr = ConfigDB().get(None, "", "SEQR")

    async def body(self):
        prev_num = 0
        cur_num = 1
        fib_list = [prev_num, cur_num]
        for _ in range(7):
            sum = await do_add(self.seqr, prev_num, cur_num)
            fib_list.append(sum)
            prev_num = cur_num
            cur_num = sum
        uvm_root().logger.info("Fibonacci Sequence: " + str(fib_list))
        uvm_root().set_logging_level_hier(CRITICAL)

class Driver(uvm_driver):

    def __init__(self, name, parent):
        super().__init__(name, parent)
        #self.transaction_id = 0

    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    def start_of_simulation_phase(self):
        self.bfm = TinyAluBfm()

    async def launch_tb(self):
        await self.bfm.reset()
        self.bfm.start_bfm()

    async def run_phase(self):
        await self.launch_tb()
        temp_op = 0
        while True:
            cmd = await self.seq_item_port.get_next_item()
            #self.parent.shared_cmd_queue.append(cmd)  # Add the seq_item to the shared queue
            #self.parent.new_cmd_event.set()
            result = await self.bfm.send_op_to_dut(cmd.a, cmd.b, temp_op)
            temp_op = cmd.op
            #self.ap.write(result)
            cmd.result = result
            self.seq_item_port.item_done()


@vsc.covergroup
class ALUCoverage(object):
    def __init__(self,a,b,op):      
        
        super().__init__()
        
        
        self.operation_cvg = vsc.coverpoint(op,
                                        bins={
                                            "Ops.ADD":vsc.bin(0), 
                                            "Ops.SUB":vsc.bin(1), 
                                            "Ops.NOT":vsc.bin(2), 
                                            "Ops.NOR":vsc.bin(3), 
                                            "Ops.NAND":vsc.bin(4), 
                                            "Ops.AND":vsc.bin(5), 
                                            "Ops.OR":vsc.bin(6), 
                                            "Ops.XOR":vsc.bin(7)
                                            },
                                        name="alu_op"
                                        )
        
        self.operanda_cvg = vsc.coverpoint(a,
                                        bins = {
                                            "low": vsc.bin_array([],[0,int(2**DATA_WIDTH/2)]), 
                                            "high": vsc.bin_array([],[int(2**DATA_WIDTH/2)+1,2**DATA_WIDTH-1])
                                            }, 
                                        name="alu_operand_a"
                                        )

        self.operandb_cvg = vsc.coverpoint(b,
                                        bins = {
                                            "low": vsc.bin_array([],[0,int(2**DATA_WIDTH/2)]), 
                                            "high": vsc.bin_array([],[int(2**DATA_WIDTH/2)+1,2**DATA_WIDTH-1])
                                            }, 
                                        name="alu_operand_b"
                                        )

        self.cross_a_b = vsc.cross([self.operanda_cvg,self.operandb_cvg])






class Coverage(uvm_subscriber):

    def end_of_elaboration_phase(self):
        pass
    
    def write(self, cmd):
        (a, b, op) = cmd
        alu_cov = ALUCoverage(lambda:a, lambda:b, lambda:op)
        alu_cov.sample()
        

    def report_phase(self):
        try:
            disable_errors = ConfigDB().get(
                self, "", "DISABLE_COVERAGE_ERRORS")
        except UVMConfigItemNotFound:
            disable_errors = False
        if not disable_errors:
            vsc.report_coverage(details=True)
            vsc.write_coverage_db("coverage_result_pyvsc.xml")


class Scoreboard(uvm_component):

    def build_phase(self):
        self.cmd_fifo = uvm_tlm_analysis_fifo("cmd_fifo", self)
        self.result_fifo = uvm_tlm_analysis_fifo("result_fifo", self)
        self.cmd_get_port = uvm_get_port("cmd_get_port", self)
        self.result_get_port = uvm_get_port("result_get_port", self)
        self.cmd_export = self.cmd_fifo.analysis_export
        self.result_export = self.result_fifo.analysis_export

    def connect_phase(self):
        self.cmd_get_port.connect(self.cmd_fifo.get_export)
        self.result_get_port.connect(self.result_fifo.get_export)

    def check_phase(self):
        passed = True
        try:
            self.errors = ConfigDB().get(self, "", "CREATE_ERRORS")
        except UVMConfigItemNotFound:
            self.errors = False
        while self.result_get_port.can_get():
            sequence_sim_time = current_sim_time('ns')
            _, actual_result = self.result_get_port.try_get()
            cmd_success, cmd = self.cmd_get_port.try_get()
            if not cmd_success:
                self.logger.critical(f"result {actual_result} had no command")
            else:
                (A, B, op_numb) = cmd
                op = Ops(op_numb)
                predicted_result = alu_prediction(A, B, op, self.errors)
                if predicted_result == actual_result:
                    # self.logger.info(f"At {sequence_sim_time} ns, PASSED: 0x{A:08x} {op.name} 0x{B:08x} ="
                    #                  f" 0x{actual_result:08x}")
                    pass
                else:
                    self.logger.error(f"FAILED: 0x{A:08x} {op.name} 0x{B:08x} "
                                      f"= 0x{actual_result:08x} "
                                      f"expected 0x{predicted_result:08x}")
                    passed = False
        assert passed


class Monitor(uvm_component):
    def __init__(self, name, parent, method_name, env):
        super().__init__(name, parent)
        self.method_name = method_name
        self.env = env

    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)
        self.bfm = TinyAluBfm()
        self.get_method = getattr(self.bfm, self.method_name)

    async def run_phase(self):
        temp = 0
        counter = 0
        while True:
            datum = await self.get_method()
            #print(self.env.shared_sequence)
            #print(self.get_method)
            if((self.method_name == "get_result")&(self.env.shared_sequence == True)):
                if(counter == 0):
                    self.ap.write(temp)
                if(counter >= 2):
                    self.ap.write(datum)
                counter += 1
            else:
                self.ap.write(datum)
            

class AluEnv(uvm_env):

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.shared_sequence = False
        #self.new_cmd_event = asyncio.Event()
        #self.shared_cmd_queue = []

    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        ConfigDB().set(None, "*", "SEQR", self.seqr)
        self.driver = Driver.create("driver", self)

        self.cmd_mon = Monitor("cmd_mon", self, "get_cmd", self)
        self.result_mon = Monitor("result_mon", self, "get_result", self)
        
        self.coverage = Coverage("coverage", self)
        self.scoreboard = Scoreboard("scoreboard", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
        self.cmd_mon.ap.connect(self.scoreboard.cmd_export)
        self.cmd_mon.ap.connect(self.coverage.analysis_export)
        self.result_mon.ap.connect(self.scoreboard.result_export)

class sharedEnv(AluEnv):

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.shared_sequence = True


@pyuvm.test()
class AluTest(uvm_test):
    """Test ALU with random and max values"""

    def build_phase(self):
        self.env = AluEnv("env", self)

    def end_of_elaboration_phase(self):
        self.test_all = TestAllSeq.create("test_all")


    async def run_phase(self):
        # example of access coverage objects
    
        self.raise_objection()
        num_iterations = DATA_WIDTH**2

        for i in range(num_iterations):
            #print(f"Current simulation time: {current_sim_time('ns')}")
            await self.test_all.start()
            await cocotb.triggers.Timer(100, units='ns')
            print(f"Current simulation time: {current_sim_time('ns')}")

       
        self.drop_objection()
'''
@pyuvm.test()
class ParallelTest(AluTest):
    """Test ALU random and max forked"""

    def build_phase(self):
        uvm_factory().set_type_override_by_type(TestAllSeq, TestAllForkSeq)
        super().build_phase()


@pyuvm.test()
class FibonacciTest(AluTest):
    """Run Fibonacci program"""

    def build_phase(self):
        ConfigDB().set(None, "*", "DISABLE_COVERAGE_ERRORS", True)
        uvm_factory().set_type_override_by_type(TestAllSeq, FibonacciSeq)
        return super().build_phase()


@pyuvm.test(expect_fail=True)
class AluTestErrors(AluTest):
    """Test ALU with errors on all operations"""

    def start_of_simulation_phase(self):
        ConfigDB().set(None, "*", "CREATE_ERRORS", True)


@pyuvm.test()
class Py_Seq_2SV_test(uvm_test):

    def __init__ (self, name, parent):
        super().__init__(name, parent)
        self.tran_desc = None

    def create_transaction(self):
        cmd_tr = AluSeqItem("cmd_tr", 0, 0, Ops.ADD)
        cmd_tr.randomize()
        self.tran_desc = PyTranDesc(
            name = b"random",
            rdnwr = 0,
            addr = 0x00000000,
            data0 = cmd_tr.a,
            data1 = cmd_tr.b,
            data2 = cmd_tr.op,
            data3 = 0x0000,
            status = 0
            )

    def build_phase(self):
        super().build_phase()
        self.cmd_ap = uvm_analysis_port("cmd_ap", self)
        self.result_ap = uvm_analysis_port("result_ap", self)
        self.scoreboard = Scoreboard("scoreboard", self)
        self.create_transaction()
        self.tran_back = data_process_and_wait()

    def connect_phase(self):
        super().connect_phase()
        self.cmd_ap.connect(self.scoreboard.cmd_export)
        self.result_ap.connect(self.scoreboard.result_export)

    async def run_phase(self):
        
        self.raise_objection()
        self.logger.info(f"Sending sequence to SV")
        for i in range(20):
            self.create_transaction()
            lib.Send_Seq_desc_to_S(ctypes.byref(self.tran_desc))
            await cocotb.triggers.Timer(10, units='ps')
        
        await self.tran_back.wait_for_py_seq_completion()
        
        for i in range( len(self.tran_back.array_data3)-3 ):
            
            # allign the data, to make result_data correspond to input(stimulus)
            cmd_tumple = (self.tran_back.array_data0[i], self.tran_back.array_data1[i], self.tran_back.array_data2[i+1])
            result = self.tran_back.array_data3[i+3]

            self.cmd_ap.write(cmd_tumple)
            self.result_ap.write(result)

        self.drop_objection()

class data_process_and_wait:
    def __init__(self):
        self.array_data0 = []
        self.array_data1 = []
        self.array_data2 = []
        self.array_data3 = []

    async def wait_for_py_seq_completion(self):
        while True:
            if lib.Query_Ext_seq_Test_completion():
                return
            await cocotb.triggers.Timer(20, units='ns')
            lib.Recv_Result_from_S(ctypes.byref(desc), ctypes.byref(empty))
            if empty.value:
                print("Shared py_seq_back is empty!")
            else:
                self.array_data0.append(desc.data0)
                self.array_data1.append(desc.data1)
                self.array_data2.append(desc.data2)
                self.array_data3.append(desc.data3)

@pyuvm.test()
class SV_VIP_Test(uvm_test):

    def __init__ (self, name, parent):
        super().__init__(name, parent)
        
    def build_phase(self):
        super().build_phase()

    async def run_phase(self):

        self.raise_objection()
        lib.Release_Int_seq_Test_start()
        self.logger.info(f"START SV-VIP Test!")
        await wait_for_sv_completion()
        self.logger.info(f"SV VIP SEQUENCE COMPLETED!")
        self.drop_objection()
        
async def wait_for_sv_completion():
    while True:
        if lib.Query_Int_seq_Test_completion():
            return
        await cocotb.triggers.Timer(1000, units='ns')
'''
def current_sim_time(units="ns"):
    time = cocotb.utils.get_sim_time(units)
    return f"{time} {units}"