// LICENSETEXT
//
//   Developed by :
//    Ashwani Singh <ashwani@circuitsutra.com>
//
//
// The contents of this file are subject to the licensing terms specified
// in the file LICENSE. Please consult this file for restrictions and
// limitations that may apply.
// 
// ENDLICENSETEXT

#ifndef AXI_SIMPLE_SLAVE_H_
#define AXI_SIMPLE_SLAVE_H_

#include <sstream>
#include "tlm_utils/multi_passthrough_target_socket.h"
#include "tlm_utils/multi_passthrough_initiator_socket.h"
#include "amba.h"
#include "nerios_memstore.h"

#define DUMP(name_str, message) 
//#define DUMP(name_str, message) \
  //  printf("%s::%s \n", name_str, message);

using namespace tlm_utils;
template<unsigned int BUSWIDTH>
class AHB_simple_slave:public sc_core::sc_module
{
public:
	amba::amba_slave_socket<> slave_sock;
        tlm_utils::multi_passthrough_target_socket<AHB_simple_slave <BUSWIDTH> >  slave_debug_socket;
	//sc_core::sc_in_clk clk;
	SC_HAS_PROCESS(AHB_simple_slave);
        AHB_simple_slave(sc_core::sc_module_name nm, std::string debug_port_name, std::string slave_port_name);
	~AHB_simple_slave();
private:
        bool got_new_request; // Hack for being incompatable with ACE bridge
        Nerios_store_t* memory;
	unsigned char MEM[2048];
	tlm::tlm_generic_payload *current_trans;
        std::deque<tlm::tlm_generic_payload *> current_trans_pool;
        std::deque<tlm::tlm_generic_payload *> current_data_pool;
	amba::amba_burst_size *burstsize, default_burstsize;
	unsigned int counter;
	tlm::tlm_phase current_phase;
	void responseThread();
	void masterTimingListener(gs::socket::timing_info);
	tlm::tlm_sync_enum nb_fw_transport(tlm::tlm_generic_payload & trans, tlm::tlm_phase & ph, sc_core::sc_time &delay);
        unsigned int transport_dbg(int id,tlm::tlm_generic_payload& trans);
	void end_of_elaboration();
};

template<unsigned int BUSWIDTH>
AHB_simple_slave<BUSWIDTH>::~AHB_simple_slave(){}

template<unsigned int BUSWIDTH>
AHB_simple_slave<BUSWIDTH>::AHB_simple_slave(sc_core::sc_module_name nm, std::string debug_port_name, std::string slave_port_name):sc_module(nm),
slave_sock(slave_port_name.c_str(),amba::amba_AXI,amba::amba_CT,false),
slave_debug_socket(debug_port_name.c_str())
{
	memset(MEM,0x00, 512);
	memset(&(MEM[512]), 0xff, 512);
	memset(&(MEM[1024]),0x0c, 512);
	memset(&(MEM[1536]),0x08, 512);
	slave_sock.template register_nb_transport_fw< AHB_simple_slave<BUSWIDTH> >(this, & AHB_simple_slave<BUSWIDTH>::nb_fw_transport);
        slave_debug_socket.register_transport_dbg(this, & AHB_simple_slave<BUSWIDTH>::transport_dbg);
	SC_THREAD(responseThread);
	//sensitive<<clk.pos();
	//dont_initialize();
		
         memory = new Nerios_store_t;
    
    default_burstsize.value=(BUSWIDTH+7)/8;
    current_trans=NULL;
    got_new_request = false;
	
}

template<unsigned int BUSWIDTH>
void AHB_simple_slave<BUSWIDTH>::masterTimingListener(gs::socket::timing_info)
{
	DUMP(name(),"Reached the master timing listener");
}

template<unsigned int BUSWIDTH>
void AHB_simple_slave<BUSWIDTH>::responseThread()
{
    sc_core::sc_time delay=sc_core::SC_ZERO_TIME;
    std::ostringstream msg;
    msg.str("");
    tlm::tlm_generic_payload *current_active_trans;
    tlm::tlm_generic_payload *current_active_data;
    while(true)
    {
        if(!current_trans_pool.empty())
        {
            current_active_trans = current_trans_pool.front();
            if(current_active_trans->get_command()==tlm::TLM_READ_COMMAND)
            {
                unsigned int count=0;
                unsigned int burstLen=0;

                burstLen = (unsigned int)(ceil((double)current_active_trans->get_data_length()/((double)burstsize->value)));

                while(count<burstLen)
                {
                    //if(current_phase == tlm::END_REQ|| current_phase == tlm::END_RESP)
                    //unsigned char * data= new unsigned char(burstsize->value);
                    unsigned int address= current_active_trans->get_address()+(count*burstsize->value) ;
                    unsigned char* data_ptr =  current_active_trans->get_data_ptr() + (count*burstsize->value);
                    unsigned int len; 
                    if(current_active_trans->get_data_length() < burstsize->value){
                        len = current_active_trans->get_data_length();
                    }
                    else{
                        len = burstsize->value;
                    }
                    for(unsigned j=0;j<len; j++)
                    {
                        memory->read(address+ j, 1, data_ptr + j);
                    }
                    tlm::tlm_phase ph;
                    current_active_trans->set_response_status(tlm::TLM_OK_RESPONSE);
                    //data array has been set, now transfer the transaction
                    if(count== burstLen-1){
                        current_active_trans->acquire(); //we need to acquire as the receiver might release within the call
                        ph= amba::BEGIN_LAST_RESP;
                    }
                    else
                        ph =tlm::BEGIN_RESP;
                    current_phase =  ph;
                    msg.str("");
                    msg <<"Sending the Read transaction data, "<<"BURST-COUNT="<< (count+1)<<std::endl;
                    DUMP(name(),msg.str());
                    switch(slave_sock->nb_transport_bw(*current_active_trans,ph,delay))
                    {
                        case tlm::TLM_ACCEPTED: break;
                        case tlm::TLM_UPDATED:{
                                                  if(current_phase==amba::BEGIN_LAST_RESP || current_active_trans->is_write()){
                                                      current_active_trans->release(); //we acquired the thing so we release now
                                                      current_active_trans=NULL;
                                                      current_phase = ph;
                                                      current_trans_pool.pop_front();
                                                  }
                                              }
                                                break;
                        case tlm::TLM_COMPLETED: abort();
                    }
                    count++;
                    wait(1, SC_NS);
                }
            }
            else
            {//it is a write command
                unsigned int count=0;
                unsigned int burstLen=0;

                burstLen = (unsigned int)(ceil((double)current_active_trans->get_data_length()/((double)burstsize->value)));
                unsigned int bytes_left = current_active_trans->get_data_length();

                while(count<burstLen)
                {
                    if(!current_data_pool.empty()){
                        assert(current_active_trans->get_command()==tlm::TLM_WRITE_COMMAND && "Inappropriate command with this phase.");
                        DUMP(name(),"Write Transaction:    data received");

                        current_active_data = current_data_pool.front();
                        unsigned int address= current_active_data->get_address()+(counter*(burstsize->value));
                        unsigned int data_ptr =  (counter*burstsize->value);
                        unsigned char * data=current_active_data->get_data_ptr() + (counter * (burstsize->value));
                        unsigned int len;
                        if(current_active_trans->get_data_length() < burstsize->value){
                            len = current_active_trans->get_data_length();
                        }
                        else{
                            len = burstsize->value;
                        }
                        for(unsigned int j=0; j<len; j++)
                        {
                            memory->write(address+ j, 1, data + j);
                            msg<<"byte"<<j+(counter*(len))<<" ="<< (unsigned int )data[j+(counter*(len))] <<", @ address="<<(address+j)<<std::endl;
                            DUMP(name(),msg.str());
                            msg.str("");
                        }
                        bytes_left -= len;
                        counter++;
                        tlm::tlm_phase ph= amba::END_DATA;
                        tlm::tlm_sync_enum retval=slave_sock->nb_transport_bw(*current_active_data,ph,delay);
                        assert(retval==tlm::TLM_ACCEPTED);
                        //if(current_phase==amba::BEGIN_LAST_DATA)
                        if(bytes_left == 0)
                        {
                            wait(delay);
                            wait(1,SC_NS);
                            current_active_data->set_response_status(tlm::TLM_OK_RESPONSE);
                            ph= tlm::BEGIN_RESP;
                            current_active_data->acquire(); //we need to acquire as the receiver might release within the call
                            slave_sock->nb_transport_bw(*current_active_data,ph,delay);
                            // Removing from the pool on getting end response
                            // for write, so commented below
                            current_trans_pool.pop_front();
                        }
                        current_data_pool.pop_front();
                    }
                    count++;
                    wait(1, SC_NS);
                }
            }
            wait(1, SC_NS);
        }
        else
            wait(1, SC_NS);

    }
}

template<unsigned int BUSWIDTH>
tlm::tlm_sync_enum AHB_simple_slave<BUSWIDTH>::nb_fw_transport(tlm::tlm_generic_payload & trans, tlm::tlm_phase & ph, sc_core::sc_time &delay)
{
    DUMP(name(), "Got "<<ph);
	std::ostringstream msg;
	msg.str("");
        //current_trans_pool.push_back(&trans);
	//current_trans= &trans;
	if(ph == amba::BEGIN_DATA ||
		ph == amba::BEGIN_LAST_DATA)
        {
            current_data_pool.push_back(&trans);
            current_phase = ph;
            ph = amba::END_DATA;
            return tlm::TLM_UPDATED;

        }
	else if(ph == tlm::BEGIN_REQ)
        {
            current_trans_pool.push_back(&trans);
            ph = tlm::END_REQ;
            counter=0;
            if (!slave_sock.template get_extension<amba::amba_burst_size>(burstsize, trans))
                burstsize=&default_burstsize;
            return tlm::TLM_UPDATED;
        }
	else if(ph== tlm::END_RESP)
        {
            if(current_phase== amba::BEGIN_LAST_RESP || trans.is_write()){
                trans.release(); //we acquired the thing so we release now
            }
            if(current_phase== amba::BEGIN_LAST_RESP){
                current_trans_pool.pop_front();
                //current_trans=NULL;
            }

            current_phase =ph;
        }
	else if(ph == amba::CSYSREQ_ASSERT ||
		ph == amba::CSYSREQ_DEASSERT )
		{
			DUMP(name(),"We are ignoring the low-power interface.");
		}
	else if(ph == amba::RESET_ASSERT ||
		ph ==amba::RESET_DEASSERT )
		{
			DUMP(name(),"We are ignoring the reset signal right now.");
		}
	else
			assert("Unexpected phase received from the master");
	return tlm::TLM_ACCEPTED;
}

template<unsigned int BUSWIDTH>
void AHB_simple_slave<BUSWIDTH>::end_of_elaboration()
{
	
	slave_sock.set_timing_listener_callback(this, & AHB_simple_slave::masterTimingListener);
	
	gs::socket::timing_info info;
	info.set_start_time(tlm::END_REQ,sc_core::sc_time(1,sc_core::SC_PS));
	info.set_start_time(tlm::BEGIN_RESP,sc_core::sc_time(3,sc_core::SC_PS));
	info.set_start_time(amba::END_DATA,sc_core::sc_time(2,sc_core::SC_PS));
	slave_sock.set_target_timing(info);	
	//slave_sock.activate_synchronization_protection();
}
template<unsigned int BUSWIDTH>
unsigned int AHB_simple_slave<BUSWIDTH>::transport_dbg(int id,tlm::tlm_generic_payload& trans)
{
	  tlm::tlm_command cmd = trans.get_command();
	  sc_dt::uint64   addr = trans.get_address();
	  unsigned char*  data = trans.get_data_ptr();
	  unsigned int     len = trans.get_data_length();
	  bool            done = false;

	  if ( cmd == tlm::TLM_READ_COMMAND )
          {
              memory->read(addr,len, data);
          }
	  else if ( cmd == tlm::TLM_WRITE_COMMAND )
          {
              memory->write(addr,len,data);
          }
	  return len;
}
#endif /*AXI_SIMPLE_SLAVE_H_*/
