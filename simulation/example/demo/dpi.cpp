// **************************************************************************
//
//  Author      : See AUTHORS
//  Project     : cocotb-BSHL
//  COPYRIGHT (c) 2023-24, Infineon Technologies AG. All rights reserved.
//
//  *****************************************************************************

#include <stdio.h>
#include <vpi_user.h>
#include "svdpi.h"
#include <pthread.h>
#include <stdint.h>
#include <string.h>
#include <deque>
#include <cstdint>
#include <fstream>
#include <cstdio> 

typedef struct {
   const char *name;
   uint8_t rdnwr;
   uint32_t  addr;
   uint32_t  data0;
   uint32_t  data1;
   uint32_t  data2;
   uint32_t  data3;
   int status;
} Seq_desc;

#ifdef __cplusplus
extern "C"{
#endif

void enable_Int_seq_Test();
void enable_Ext_seq_Test();

// Communication API related to Int_seq_Test

int Request_Int_seq_Test_start();
void Release_Int_seq_Test_start();
int Notify_Int_seq_Test_completion();
bool Query_Int_seq_Test_completion();

// Communication API related to Ext_seq_Test 

int Request_Ext_seq_Test_start();
void Release_Ext_seq_Test_start();
bool Query_Ext_seq_Test_completion();
int Notify_Ext_seq_Test_completion();

void Send_Seq_desc_to_S(Seq_desc *seq_desc);
void S_Send_Result_back(Seq_desc *seq_desc_back);
void Recv_Result_from_S(Seq_desc *seq_desc_back, bool *queue_empty);
int S_Recv_Seq_desc();

// api for SV side used in Ext_seq_Test
void add_seq(Seq_desc *seq_desc);
void wait_all_seq_done();
void disable_run();
svBit try_get_seq_done(Seq_desc *seq_desc);
void wait_delay_ns(unsigned time_in_ns);


#ifdef __cplusplus
}
#endif

std::deque<Seq_desc> shared_queue_seq_desc;
std::deque<Seq_desc> shared_queue_result;
static bool Int_seq_Test_completion = false;
static bool Ext_seq_Test_completion = false;
bool Int_seq_Test_start = false;
bool Ext_seq_Test_start = false;


// Communication API related to Int_seq_Test

int Request_Int_seq_Test_start() {
	if(Int_seq_Test_start == true){
		enable_Int_seq_Test();
		}
	return 0;
}

void Release_Int_seq_Test_start()
{
	Int_seq_Test_start = true;
}	

int Notify_Int_seq_Test_completion() {
    Int_seq_Test_completion = true;
	return 0;
}

bool Query_Int_seq_Test_completion() 
{
    return Int_seq_Test_completion;
}

// Communication API related to Ext_seq_Test 

int Request_Ext_seq_Test_start() {
	if(Ext_seq_Test_start == true){	
		enable_Ext_seq_Test();
		}
	return 0;
}

void Release_Ext_seq_Test_start()
{
	Ext_seq_Test_start = true;
}	

int Notify_Ext_seq_Test_completion() {
    Ext_seq_Test_completion = true;
	return 0;
}

bool Query_Ext_seq_Test_completion() 
{
    return Ext_seq_Test_completion;
}

// Desc and Result Transferring API

void Send_Seq_desc_to_S(Seq_desc *seq_desc) {
    
    shared_queue_seq_desc.push_back(*seq_desc);
    /*
    printf( "Received seq_desc struct:\n");
    printf( "name: %s\n", seq_desc->name);
    printf( "rdnwr: %d\n", seq_desc->rdnwr);
    printf( "addr: 0x%x\n", seq_desc->addr);
    printf( "data0: 0x%x\n", seq_desc->data0);
    printf("data1: 0x%x\n", seq_desc->data1);
    printf("data2: 0x%x\n", seq_desc->data2);
    printf("data3: 0x%x\n", seq_desc->data3);
    printf("status: %d\n", seq_desc->status);
    printf("#############\n\n\n");
    */
    Release_Ext_seq_Test_start();
}

int S_Recv_Seq_desc(){

    bool empty = false;
    Seq_desc seq_desc;
    printf("SV is getting Transaction...\n");
    while(!empty)
    {
        seq_desc = shared_queue_seq_desc.front();
        add_seq(&seq_desc);
        shared_queue_seq_desc.pop_front();

        if(shared_queue_seq_desc.empty()){
            printf("Queue is empty and jump out of the loop.\n");
            empty = true;
        } 
    }

    wait_all_seq_done();
    wait_delay_ns(100);
    disable_run();
    printf("Getting trans ends\n");
    return 0;
} 

void S_Send_Result_back(Seq_desc *seq_desc_back){
    shared_queue_result.push_back(*seq_desc_back);
} 

void Recv_Result_from_S(Seq_desc *seq_desc_back, bool *queue_empty){

    if(!shared_queue_result.empty()){
        *seq_desc_back = shared_queue_result.front();
        shared_queue_result.pop_front();
        *queue_empty = false;
    }
    else{
        *queue_empty = true;
    }
}