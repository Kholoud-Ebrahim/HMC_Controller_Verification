`uvm_analysis_imp_decl(_req_packet)

class HMC_Mem_Storage  extends uvm_component;
    `uvm_component_utils(HMC_Mem_Storage)
    parameter ADDRESS_WIDTH = 34;
    HMC_Req_Sequence_item Req_item;
    HMC_Rsp_Sequence_item Rsp_item;

    HMC_Req_Sequence_item Req_Transaction [$];

    // TLM analysis port from monitor to memory
    uvm_analysis_imp_req_packet #(HMC_Req_Sequence_item , HMC_Mem_Storage) mon2stg_imp; 
    uvm_analysis_port#(HMC_Rsp_Sequence_item ) stg2sqr_port;     

    // Associative Array
    HMC_Req_Sequence_item Storage [bit[ADDRESS_WIDTH-1:0]]; 

    // constructor
    function new ( string name = "HMC_Mem_Storage" , uvm_component parent = null);
        super.new(name,parent);
        `uvm_info("STORAGE_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction: new

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("STORAGE_CLASS", "Build Phase!", UVM_HIGH)

        mon2stg_imp    = new("mon2stg_imp"   , this);
        stg2sqr_port = new("stg2sqr_port", this);
    endfunction: build_phase

    // write task for monitor 
    task write(HMC_Req_Sequence_item Req_item);
        Req_Transaction.push_back(Req_item);
    endtask: write

    // Link Retry mode
    function HMC_Rsp_Sequence_item Link_Retry (HMC_Req_Sequence_item Req_item);
        Link_Retry.RES1    = 22'b0;
        Link_Retry.SLID    = Req_item.SLID;
        Link_Retry.RES2    = 6'b0;
        Link_Retry.TGA     = 9'b0;
        Link_Retry.TAG     = Req_item.TAG; // 9'h0
        Link_Retry.DLN     = 4'b0001;
        Link_Retry.LNG     = 4'b0001;
        Link_Retry.RES3    = 1'b0;
        Link_Retry.CMD     = IRTRY;

        Link_Retry.CRC     = Req_item.CRC;
        Link_Retry.RTC     = Req_item.RTC;
        Link_Retry.ERRSTAT = 7'b0;
        Link_Retry.DINV    = 1'b0;
        Link_Retry.SEQ     = Req_item.SEQ;
        Link_Retry.FRP     = Req_item.FRP;
        Link_Retry.RRP     = Req_item.RRP;
    endfunction: Link_Retry

    // Write packet to the storage
    function void write_req_packet(HMC_Req_Sequence_item Req_item);
        Storage[Req_item.ADRS]= Req_item;
    endfunction: write_req_packet

    function HMC_Rsp_Sequence_item write_rsp_packet(HMC_Req_Sequence_item Req_item);
        write_rsp_packet.RES1    = 22'b0;
        write_rsp_packet.SLID    = Req_item.SLID;
        write_rsp_packet.RES2    = 6'b0;
        write_rsp_packet.TGA     = 9'b0;
        write_rsp_packet.TAG     = Req_item.TAG;
        write_rsp_packet.DLN     = 4'b0001;
        write_rsp_packet.LNG     = 4'b0001;
        write_rsp_packet.RES3    = 1'b0;
        write_rsp_packet.CMD     = WR_RS;

        write_rsp_packet.CRC     = 32'b0;
        write_rsp_packet.RTC     = Req_item.RTC;
        write_rsp_packet.ERRSTAT = 7'b0;
        write_rsp_packet.DINV    = 1'b0;
        write_rsp_packet.SEQ     = Req_item.SEQ;
        write_rsp_packet.FRP     = Req_item.FRP;
        write_rsp_packet.RRP     = Req_item.RRP;

        // Calculating CRC for the Write RSP packet
        write_rsp_packet.CRC = write_rsp_packet.calculate_crc();  
        
    endfunction: write_rsp_packet

    // Read packet from the storage
    function HMC_Rsp_Sequence_item read_packet(HMC_Req_Sequence_item Req_item);
        if(! Storage.exists(Req_item.ADRS))
            `uvm_warning("STORAGE_CLASS","Address is not in the storage")

        else begin
            `uvm_info("STORAGE_CLASS","Address is in the storage", UVM_HIGH)
            read_packet = read_rsp_packet(Storage[Req_item.ADRS]); // DLN   LNG   data

            read_packet.RES1    = 22'b0;
            read_packet.SLID    = Req_item.SLID;
            read_packet.RES2    = 6'b0;
            read_packet.TGA     = 9'b0;
            // Tags in READ requests are returned with the respective read data in the read response packet header
            // read_packet.TAG  : done in read_rsp_packet function we don't need to overwrite its value
            read_packet.RES3    = 1'b0;
            read_packet.CMD     = RD_RS;

            read_packet.CRC     = 32'b0;
            read_packet.RTC     = Req_item.RTC;
            read_packet.ERRSTAT = 7'b0;
            read_packet.DINV    = 1'b0;
            read_packet.SEQ     = Req_item.SEQ;
            read_packet.FRP     = Req_item.FRP;
            read_packet.RRP     = Req_item.RRP;

            // Calculating CRC for the Write RSP packet
            read_packet.CRC = read_packet.calculate_crc(); 
        end
    endfunction: read_packet

    function HMC_Rsp_Sequence_item read_rsp_packet(HMC_Req_Sequence_item stored_item);
        read_rsp_packet.RES1    = 22'b0;
        read_rsp_packet.SLID    = stored_item.SLID;
        read_rsp_packet.RES2    = 6'b0;
        read_rsp_packet.TGA     = 9'b0;
        read_rsp_packet.TAG     = stored_item.TAG;
        read_rsp_packet.RES3    = 1'b0;
        read_rsp_packet.CMD     = RD_RS;

        if (stored_item.data.size() == 0) begin
            read_rsp_packet.DLN     = 4'b0001;
            read_rsp_packet.LNG     = 4'b0001;
        end
        else if(stored_item.data.size() == 2)begin
            read_rsp_packet.DLN     = 4'b0010;
            read_rsp_packet.LNG     = 4'b0010;
        end
        else begin
            read_rsp_packet.DLN     = (stored_item.data.size() - 2)/2 +2;
            read_rsp_packet.LNG     = (stored_item.data.size() - 2)/2 +2;
        end
        
        read_rsp_packet.data    = stored_item.data;

        read_rsp_packet.CRC     = stored_item.CRC;
        read_rsp_packet.RTC     = stored_item.RTC;
        read_rsp_packet.ERRSTAT = 7'b0;
        read_rsp_packet.DINV    = 1'b0;
        read_rsp_packet.SEQ     = stored_item.SEQ;
        read_rsp_packet.FRP     = stored_item.FRP;
        read_rsp_packet.RRP     = stored_item.RRP;     

    endfunction: read_rsp_packet

    // Error
    function HMC_Rsp_Sequence_item error_rsp_packet(HMC_Req_Sequence_item Req_item);
        error_rsp_packet.RES1    = 22'b0;            // [63:42]
        error_rsp_packet.SLID    = Req_item.SLID;    // [41:39]
        error_rsp_packet.RES2    = 6'b0;             // [38:33] 
        error_rsp_packet.TGA     = 9'b0;             // [32:24]
        error_rsp_packet.TAG     = Req_item.TAG;     // [23:15]
        error_rsp_packet.RES3    = 1'b0;             // [6]

        /*
            Invalid command: An unsupported command existed in a request packet. 
            Rsp: Write response packet(TAG = tag of corresponding request)
        */
        if(Req_item.CMD != NULL_req||PRET_req||TRET_req||IRTRY_req||WR16||WR32||WR48||WR64||WR80||WR96||WR112||WR128||TWO_ADD8||ADD16||P_WR16||P_WR32||P_WR48||P_WR64||P_WR80||P_WR96||P_WR112||P_WR128||P_TWO_ADD8||P_ADD16||RD16||RD32||RD48||RD64||RD80||RD96||RD112||RD128) begin
            error_rsp_packet.DLN     = 4'b0001;     // [14:11]
            error_rsp_packet.LNG     = 4'b0001;     // [10:7]
            error_rsp_packet.CMD     = WR_RS;       // [5:0] 
            error_rsp_packet.ERRSTAT = 7'b0110000;  // [26:20]
        end

        /*
            Invalid length: An invalid length was specified for the given command in a request packet. 
            Read response packet(TAG = tag of corresponding request)
        */
        else if(Req_item.LNG >= 10)begin
            error_rsp_packet.DLN     = 4'b0001;     // [14:11]
            error_rsp_packet.LNG     = 4'b0001;     // [10:7]
            error_rsp_packet.CMD     = RD_RS;       // [5:0] 
            error_rsp_packet.ERRSTAT = 7'b0110001;  // [26:20]
        end

        error_rsp_packet.CRC     = 32'b0;  // [63:32]
        error_rsp_packet.RTC     = Req_item.RTC;  // [31:27]
        error_rsp_packet.DINV    = 1'b0;          // [19]
        error_rsp_packet.SEQ     = Req_item.SEQ;  // [18:16]
        error_rsp_packet.FRP     = Req_item.FRP;  // [15:8]
        error_rsp_packet.RRP     = Req_item.RRP;  // [7:0]

        // Calculating CRC for the Write RSP packet
        error_rsp_packet.CRC = error_rsp_packet.calculate_crc(); 
    endfunction: error_rsp_packet

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("STORAGE_CLASS", "Run Phase!", UVM_HIGH)
        
        forever begin
            HMC_Req_Sequence_item Current_Req_Transaction;

            Rsp_item = HMC_Rsp_Sequence_item::type_id::create("Rsp_item");

            wait(Req_Transaction.size() != 0 );
            Current_Req_Transaction = Req_Transaction.pop_front();

            //Invalid length
            if(Current_Req_Transaction.LNG >= 10) begin
                Rsp_item = error_rsp_packet(Current_Req_Transaction);
            end
            
            //Valid length
            else begin
                

                // Flow Commands   IRTRY = 6'b000011
                if (Current_Req_Transaction.CMD == IRTRY_req) begin
                    Rsp_item = Link_Retry(Current_Req_Transaction);
                end
                
                /*
                    // WRITE requests
                    WR16  = 6'b001000, WR32  = 6'b001001, WR48 = 6'b001010,
                    WR64  = 6'b001011, WR80  = 6'b001100, WR96 = 6'b001101,
                    WR112 = 6'b001110, WR128 = 6'b001111
                    // ATOMIC Requests
                    TWO_ADD8= 6'b010010, ADD16 = 6'b010011
                */
                else if(Current_Req_Transaction.CMD == WR16||WR32||WR48||WR64||WR80||WR96||WR112||WR128||TWO_ADD8||ADD16) begin
                    write_req_packet(Current_Req_Transaction);
                    Rsp_item = write_rsp_packet(Current_Req_Transaction);  
                end

                /*
                    // Posted Write Request: not waiting any response
                    P_WR16  = 6'b011000, P_WR32  = 6'b011001, P_WR48 = 6'b011010,
                    P_WR64  = 6'b011011, P_WR80  = 6'b011100, P_WR96 = 6'b011101,
                    P_WR112 = 6'b011110, P_WR128 = 6'b011111
                    //POSTED ATOMIC Requests
                    P_TWO_ADD8 = 6'b100010, P_ADD16 = 6'b100011
                */
                else if (Current_Req_Transaction.CMD == P_WR16||P_WR32||P_WR48||P_WR64||P_WR80||P_WR96||P_WR112||P_WR128||P_TWO_ADD8||P_ADD16) begin
                    write_req_packet(Current_Req_Transaction);
                end

                /*
                    //READ Requests
                    RD16  = 6'b110000, RD32  = 6'b110001, RD48 = 6'b110010,
                    RD64  = 6'b110011, RD80  = 6'b110100, RD96 = 6'b110101,
                    RD112 = 6'b110110, RD128 = 6'b110111
                */
                else if (Current_Req_Transaction.CMD == RD16||RD32||RD48||RD64||RD80||RD96||RD112||RD128) begin
                    Rsp_item = read_packet(Current_Req_Transaction);  
                end
                
                // Invalid command
                else begin 
                    Rsp_item = error_rsp_packet(Current_Req_Transaction);
                end
            end
            // Passing the Response packet to the Sequencer via the analysis port write() 
            stg2sqr_port.write(Rsp_item);
        end
    endtask: run_phase
endclass: HMC_Mem_Storage