# **************************************************************************
#
#  Author      : See AUTHORS
#  Project     : cocotb-BSHL
#  Description : defines the TinyALU Bus Function Model (bfm)
#  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
#
#  *****************************************************************************

import cocotb
from cocotb.triggers import FallingEdge
from cocotb.queue import QueueEmpty, Queue
import enum
import logging

from pyuvm import utility_classes

logging.basicConfig(level=logging.NOTSET)
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


@enum.unique
class Ops(enum.IntEnum):
    """Legal ops for the TinyALU"""
    ADD = 0
    SUB = 1
    NOT = 2
    NOR = 4
    NAND= 3
    AND = 5
    OR  = 6
    XOR = 7



def alu_prediction(A, B, op, error=False):
    """Python model of the TinyALU"""
    assert isinstance(op, Ops), "The tinyalu op must be of type Ops"
    if op == Ops.ADD:
        result = (A + B) & 0xffffffff
    elif op == Ops.SUB:
        result = (A - B) & 0xffffffff
    elif op == Ops.NOT:
        result = ~A & 0xffffffff
    elif op == Ops.NOR:
        result = ~(A | B) & 0xffffffff
    elif op == Ops.NAND:
        result = ~(A & B) & 0xffffffff
    elif op == Ops.AND:
        result = A & B
    elif op == Ops.OR:
        result = A | B
    elif op == Ops.XOR:
        result = A ^ B
    if error:
        result = result + 1
        #print("chuan jin lai ge ERROR")
    return result


def get_int(signal):
    try:
        sig = int(signal.value)
    except ValueError:
        sig = 0
    return sig


class TinyAluBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.dut_driver_queue = Queue(maxsize=1)
        self.result_driver_queque = Queue(maxsize=0)
        self.cmd_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_op_to_dut(self, aa, bb, op):
        command_tuple = (aa, bb, op)
        await self.dut_driver_queue.put(command_tuple)
        result = await self.result_driver_queque.get()
        return result

    async def get_cmd(self):
        cmd = await self.cmd_mon_queue.get()
        return cmd

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result
    
    async def reset(self):
        await FallingEdge(self.dut.dut.clk)
        self.dut.dut.a.value = 0
        self.dut.dut.b.value = 0
        self.dut.dut.op.value = 0
        self.dut.rm.a.value = 0
        self.dut.rm.b.value = 0
        self.dut.rm.op.value = 0
        self.dut.input_if.a.value = 0
        self.dut.input_if.b.value = 0
        self.dut.input_if.op.value = 0
        await FallingEdge(self.dut.dut.clk)

    async def driver_bfm(self):
        #self.dut.dut.a.value = 0
        #self.dut.dut.b.value = 0
        #self.dut.dut.op.value = 0
        #self.dut.rm.a.value = 0
        #self.dut.rm.b.value = 0
        #self.dut.rm.op.value = 0
        #self.dut.input_if.a.value = 0
        #self.dut.input_if.b.value = 0
        #self.dut.input_if.op.value = 0
        while True:
            await FallingEdge(self.dut.dut.clk)
            try:
                (aa, bb, op) = self.dut_driver_queue.get_nowait()
                self.dut.dut.a.value = aa
                self.dut.dut.b.value = bb

                self.dut.rm.a.value = aa
                self.dut.rm.b.value = bb

                self.dut.input_if.a.value = aa
                self.dut.input_if.b.value = bb
                
                self.dut.dut.op.value = op
                self.dut.rm.op.value = op
                self.dut.input_if.op.value = op
                
            except QueueEmpty:
                pass

    async def cmd_mon_bfm(self):
        mon_a = 0
        mon_b = 0
        while True:
            await FallingEdge(self.dut.dut.clk)
            cmd_tuple = (mon_a,
                         mon_b,
                         get_int(self.dut.dut.op))
            mon_a = get_int(self.dut.dut.a)
            mon_b = get_int(self.dut.dut.b)
            #print("Detecting input and send it to mon_queue")
            self.cmd_mon_queue.put_nowait(cmd_tuple)

    async def result_mon_bfm(self):
        while True:
            await FallingEdge(self.dut.dut.clk)
            result = get_int(self.dut.dut.r)
            #print("Detecting output and send it to mon_queue")
            self.result_driver_queque.put_nowait(result)
            self.result_mon_queue.put_nowait(result)

    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.cmd_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())
