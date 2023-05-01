class AXI_Req_Driver#(parameter FPW=4) extends uvm_driver#(AXI_Req_Sequence_Item);

	 `uvm_component_param_utils(AXI_Req_Driver#(FPW))
	 virtual AXI_Req_IF#(FPW) VIF;
	AXI_Req_Sequence_Item  req_seq_item;
	
	extern function new (string name="AXI_Req_Driver", uvm_component parent = null);
	extern  function void build_phase (uvm_phase phase);
	extern  task run_phase (uvm_phase phase);
	extern  task drive_item();
	extern  task CREATE_PACKET_TDATA_TUSER();
	
	
 endclass: AXI_Req_Driver

 ////////////////////////////constructor/////////////////////////
 function AXI_Req_Driver::new(string name="AXI_Req_Driver", uvm_component parent = null);
	super.new(name,parent);
 endfunction: new 
	
 ////////////////////////////build phase///////////////////////
 function void AXI_Req_Driver::build_phase (uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db#(virtual AXI_Req_IF)::get(this,"","AXI_Req_VIF",VIF))
	      `uvm_fatal("AXI_Req_Driver ","failed to access AXI_Req_VIF from req_seq_item.database");
		
	`uvm_info("AXI_Req_Driver"," build phase ",UVM_HIGH)
		
 endfunction: build_phase
	
 /////////////////////////run phase////////////////////////
 task AXI_Req_Driver::run_phase (uvm_phase phase);
	super.run_phase(phase);
	`uvm_info("AXI_Req_Driver"," run phase ",UVM_HIGH)
    forever begin 
	    req_seq_item=AXI_Req_Sequence_Item::type_id::create("req_seq_item");
	    seq_item_port.get_next_item(req_seq_item);
	        drive_item();
	    seq_item_port.item_done();
	end
 endtask: run_phase
	
 ///////////////////////drive_item///////////////////////
 task AXI_Req_Driver:: drive_item();
	@(posedge VIF.clk);
	if(!VIF.rst) begin //reset is active low
        VIF.TVALID<=0;
	VIF.TDATA<=0;
        VIF.TUSER<=0; 
	@(posedge VIF.clk);
        VIF.TVALID<=1;
	end
	else begin 
	    @(posedge VIF.clk);
		//VIF.TVALID<=1;  
		if(VIF.TREADY)begin 
            CREATE_PACKET_TDATA_TUSER();
		    @(posedge VIF.clk);
		end 
	end
 endtask:drive_item
 
 task AXI_Req_Driver::CREATE_PACKET_TDATA_TUSER();
    
    bit[63:0] header;
    bit RES1=0;
    bit[2:0] RES2=0;
    bit[63:0] tail;
    bit[4:0] RES3=0;
    bit[127:0] flit;
    //bit[63:0] data[$];
    bit[127:0] flits[$];
	
    bit[127:0] Tdata_queue[$:3];//FPW=4;
    bit[FPW*128-1:0] Tdata;
    bit[FPW*16-1:0] TUSER;
    bit tuser_hdr[$];
    bit tuser_valid[$];
    bit tuser_tail[$];
    bit t_hdr[$:3];//FPW=4
    bit t_valid[$:3];//FPW=4
    bit t_tail[$:3];//FPW=4
    bit[FPW-1:0]TUSR_TAIL;
    bit[FPW-1:0] TUSR_HDR;
    bit[FPW-1:0] TUSR_VALID;
    int cycle=0;
    int i=0;
	
    //the header of the packet
    header={req_seq_item.CUB,RES2,req_seq_item.ADRS,req_seq_item.TAG,req_seq_item.DLN,req_seq_item.LNG,RES1,req_seq_item.CMD};
   //the tail of the packet
    tail={req_seq_item.CRC,req_seq_item.RTC,req_seq_item.SLID,RES3,req_seq_item.SEQ,req_seq_item.FRP,req_seq_item.RRP};
    tail={64'b0};
	
    /* if(req_seq_item.LNG>=3) begin
	for(int i=0;i<(req_seq_item.LNG*2)-2;i++)begin 
	   data[i]=$random;
        end
     end
     else if(req_seq_item.LNG==2) begin
	for(int i=0;i<req_seq_item.LNG;i++)begin 
	   data[i]=$random;
	end
     end*/
	
    flits.delete();
	
	case(req_seq_item.LNG)
	    1:begin//  LNG = 1 means that the packet contains no data FLITs 
	          flit={header,tail};
		  flits.push_back(flit);
		  tuser_hdr.push_back(1);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(1);
		 end
	    2:begin 
		  flit={header,req_seq_item.data[0]};
		  flits.push_back(flit); 
		  tuser_hdr.push_back(1);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(0);
		  flit={req_seq_item.data[1],tail};
		  flits.push_back(flit); 
		  tuser_hdr.push_back(0);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(1);
		  end
	    3:begin
		  flit={header,req_seq_item.data[0]};
		  flits.push_back(flit); 
		  tuser_hdr.push_back(1);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(0);
		  flit={req_seq_item.data[1],req_seq_item.data[2]};
		  flits.push_back(flit);
		  tuser_valid.push_back(1);
		  tuser_hdr.push_back(0);
		  tuser_tail.push_back(0);
		  flit={req_seq_item.data[3],tail};
		  flits.push_back(flit);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(1);
		  tuser_hdr.push_back(0);
        end
        default: begin 
		  flit={header,req_seq_item.data[0]};
		  flits.push_back(flit); 
		  tuser_hdr.push_back(1);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(0);

		  for(int i=1;i<req_seq_item.LNG;i++) begin
		    flit={req_seq_item.data[i],req_seq_item.data[i++]};
           	    flits.push_back(flit);
		    tuser_valid.push_back(1);
			tuser_hdr.push_back(0);
		    tuser_tail.push_back(0);
		  end
		  flit={req_seq_item.data[req_seq_item.LNG+1],tail};
		  flits.push_back(flit);
		  tuser_valid.push_back(1);
		  tuser_tail.push_back(1);
		  tuser_hdr.push_back(0);
		end
	endcase
	
	while(flits.size()!=0 && cycle<FPW) begin 
	   for(int j=0;j<FPW;j++) begin
	      if(flits.size()==0)begin
		  
	        tuser_hdr.push_back(0);
		    tuser_valid.push_back(0);
		    tuser_tail.push_back(0);
	      end
	      Tdata_queue.push_back(flits.pop_front());
	     //$display(" Tdata_queue[%0d]=%b",j, Tdata_queue[j]);
	     t_hdr.push_back(tuser_hdr.pop_front());
	     t_tail.push_back(tuser_tail.pop_front());
	     t_valid.push_back(tuser_valid.pop_front());
	    if(FPW==2) begin
		
	       Tdata={Tdata_queue[j],Tdata_queue[j-1]};
	       TUSR_TAIL= {t_tail[j],t_tail[j-1]};
	       TUSR_HDR={t_hdr[j],t_hdr[j-1]};
	       TUSR_VALID={t_valid[j],t_valid[j-1]};
               TUSER={TUSR_TAIL,TUSR_HDR,TUSR_VALID};
	    end
           else if(FPW==4) begin
		   
	       Tdata={Tdata_queue[j],Tdata_queue[j-1],Tdata_queue[j-2],Tdata_queue[j-3]};
	       TUSR_TAIL= {t_tail[j],t_tail[j-1],t_tail[j-2],t_tail[j-3]};
	       TUSR_HDR={t_hdr[j],t_hdr[j-1],t_hdr[j-2],t_hdr[j-3]};
	       TUSR_VALID={t_valid[j],t_valid[j-1],t_valid[j-2],t_valid[j-3]};
               TUSER={TUSR_TAIL,TUSR_HDR,TUSR_VALID};
	   end
	  else if(FPW==6) begin
	  
	      Tdata={128'b0,128'b0,Tdata_queue[j],Tdata_queue[j-1],Tdata_queue[j-2],Tdata_queue[j-3],Tdata_queue[j-4],Tdata_queue[j-5]};
	      TUSR_TAIL= {t_tail[j],t_tail[j-1],t_tail[j-2],t_tail[j-3],t_tail[j-4],t_tail[j-5]};
	      TUSR_HDR={t_hdr[j],t_hdr[j-1],t_hdr[j-2],t_hdr[j-3],t_hdr[j-4],t_hdr[j-5]};
	      TUSR_VALID={t_valid[j],t_valid[j-1],t_valid[j-2],t_valid[j-3],t_valid[j-4],t_valid[j-5]};
          TUSER={TUSR_TAIL,TUSR_HDR,TUSR_VALID};
	   end
	  else if(FPW==8) begin
	      Tdata={Tdata_queue[j],Tdata_queue[j-1],Tdata_queue[j-2],Tdata_queue[j-3],Tdata_queue[j-4],Tdata_queue[j-5],Tdata_queue[j-6],Tdata_queue[j-7]};
	      TUSR_TAIL= {t_tail[j],t_tail[j-1],t_tail[j-2],t_tail[j-3],t_tail[j-4],t_tail[j-5],t_tail[j-6],t_tail[j-7]};
	      TUSR_HDR={t_hdr[j],t_hdr[j-1],t_hdr[j-2],t_hdr[j-3],t_hdr[j-4],t_hdr[j-5],t_hdr[j-6],t_hdr[j-7]};
	      TUSR_VALID={t_valid[j],t_valid[j-1],t_valid[j-2],t_valid[j-3],t_valid[j-4],t_valid[j-5],t_valid[j-6],t_valid[j-7]};
          TUSER={TUSR_TAIL,TUSR_HDR,TUSR_VALID};
	   end
		  //$display("Tdata=%b",Tdata);
		 //TUSER={t_tail,t_hdr,t_valid};
		if(flits.size()==0)begin
		  
	        tuser_hdr.push_back(0);
		    tuser_valid.push_back(0);
		    tuser_tail.push_back(0);
	    end
	   end
	   
        $display("t_hdr = %p",t_hdr);
        $display("t_tail = %p",t_tail);
        $display("t_valid = %p",t_valid);
        $display("tuser =%b",TUSER);
	    $display("Tdata=%b",data);
		
	    VIF.TDATA<=Tdata;
	    VIF.TUSER<=TUSER;
	    VIF.TVALID<=1;
		
	   while(i<FPW)begin 
         Tdata_queue.pop_front();
	      t_hdr.pop_front();
              t_tail.pop_front();
              t_valid.pop_front();
	      i++;
	   end
	   $display("cycle=%d",cycle);
	   cycle++;
	end
	
	
 endtask :CREATE_PACKET_TDATA_TUSER
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 