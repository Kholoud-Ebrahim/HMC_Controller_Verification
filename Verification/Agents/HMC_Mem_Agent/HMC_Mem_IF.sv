interface HMC_Mem_IF#(parameter DWIDTH = 128, NUM_LANES = 8);
	
	logic clk_hmc;
    logic res_n_hmc;

    // Connect Transceiver
    logic  [DWIDTH-1:0]      phy_data_tx_link2phy;//output: Connect!
    logic  [DWIDTH-1:0]      phy_data_rx_phy2link;//input : Connect!
    logic  [NUM_LANES-1:0]   phy_bit_slip;        //output: Must be connected if DETECT_LANE_POLARITY==1 AND CTRL_LANE_POLARITY=0
    logic  [NUM_LANES-1:0]   phy_lane_polarity;   //output: All 0 if CTRL_LANE_POLARITY=1
    logic                    phy_tx_ready;        //input : Optional information to RF
    logic                    phy_rx_ready;        //input : Release RX descrambler reset when PHY ready
    logic                    phy_init_cont_set;   //output: Can be used to release transceiver reset if used
    // Connect HMC
    logic              P_RST_N;   //output:RF
    logic              LXRXPS;    //output
    logic              LXTXPS;    //input
    logic              FERR_N;    //input:RF

    // Timing parameters
    int tRST   = 20ns;// Assertion time for P_RST_N
	int tINIT  = 1us; // 20ms in the spec, but that would take too long in simulation
	int tRESP1 = 1us; // 1us or 1.2ms with DFE
	int tRESP2 = 1us; // 1us

endinterface: HMC_Mem_IF