 class AXI_Req_Config extends uvm_object;
   
   'uvm_ogject_utils(AXI_Req_Config)
    uvm_active_passive_enum is_active= UVM_ACTIVE;
    
    extern function new (string name="AXI_Req_Config");
	
 endclass: AXI_Req_Config

 function AXI_Req_Config::new(string name="AXI_Req_Config", uvm_component parent = null);
	super.new(name);
 endfunction: new 
