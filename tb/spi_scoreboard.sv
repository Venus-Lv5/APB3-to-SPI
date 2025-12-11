`uvm_analysis_imp_decl(_mosi)
`uvm_analysis_imp_decl(_miso)
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_ss)
`uvm_analysis_imp_decl(_sclk_freq)

class spi_scoreboard extends uvm_scoreboard;
   `uvm_component_utils(spi_scoreboard);
   `include "spi_coverage.sv"

   uvm_analysis_imp_apb       #(apb_transaction, spi_scoreboard)  apb_export;
   uvm_analysis_imp_mosi      #(spi_transaction, spi_scoreboard)  mosi_export;
   uvm_analysis_imp_miso      #(spi_transaction, spi_scoreboard)  miso_export;
   uvm_analysis_imp_ss        #(bit [3:0],       spi_scoreboard)  ss_export;
   uvm_analysis_imp_sclk_freq #(int,         		spi_scoreboard)  sclk_freq_export;

   spi_transaction spi_mosi_queue[$];
   spi_transaction spi_miso_queue[$];

   apb_transaction apb_tx_queue[$];
   apb_transaction apb_rx_queue[$];
   apb_transaction apb_lcr_queue[$];
   apb_transaction apb_dlr_queue[$];
   apb_transaction apb_fsr_queue[$];
   apb_transaction apb_rsvd_queue[$];

   bit [3:0] ss_queue[$];
   int 		 sclk_freq_queue[$];

   apb_transaction apb_tx_trans;
   apb_transaction apb_rx_trans;
   apb_transaction apb_lcr_trans;
   apb_transaction apb_dlr_trans;
   apb_transaction apb_fsr_trans;
   apb_transaction apb_rsvd_trans;

   spi_transaction spi_mosi_trans;
   spi_transaction spi_miso_trans;

   bit [3:0] ss;
   int 		 sclk_freq;
   
   spi_configuration cfg;
   apb_configuration apb_freq;
   uvm_status_e status;

   bit[31:0] tbr_data      		= 31'b0;

   int tx_count;
   int ss_count;
   

   function new(string name = "spi_scoreboard", uvm_component parent);
      super.new(name, parent);
      	coverage_cfg = new();
		SPI_COVERGROUP = new();
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if(!uvm_config_db#(spi_configuration)::get(this, "", "cfg", cfg))
         `uvm_fatal(get_type_name(), "Failed to get cfg from uvm_config_db")
      if(!uvm_config_db#(apb_configuration)::get(this, "", "apb_freq", apb_freq))
         `uvm_fatal(get_type_name(), "Failed to get apb_configuration from uvm_config_db")

      mosi_export       = new("mosi_export", this);
      miso_export       = new("miso_export", this);
      apb_export        = new("apb_export", this);
      ss_export         = new("ss_export", this);
      sclk_freq_export  = new("sclk_freq_export", this);
      
      sample_spi_fc(cfg, apb_freq);
      tx_count = 0;
      ss_count = 0;
   endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
   endtask : run_phase

   virtual function void write_mosi (spi_transaction trans);
      `uvm_info("run_phase", $sformatf("Get frame data from MOSI: \n%s", trans.sprint()), UVM_LOW)
      spi_mosi_queue.push_back(trans);
   endfunction

   virtual function void write_miso (spi_transaction trans);
      `uvm_info("run_phase", $sformatf("Get frame data from MISO: \n%s", trans.sprint()), UVM_LOW)
      spi_miso_queue.push_back(trans);
   endfunction

   virtual function void write_ss (bit [3:0] trans);
      `uvm_info("run_phase", $sformatf("Get slaver id from SS: %b", trans), UVM_LOW)
      ss_queue.push_back(trans);
   endfunction 
   
   virtual function void write_sclk_freq (int trans);
      `uvm_info("run_phase", $sformatf("Get freq of SCLK: %0d", trans), UVM_LOW)
      sclk_freq_queue.push_back(trans);
   endfunction 

   virtual function void write_apb (apb_transaction trans);
      if(trans.xact_type == apb_transaction::WRITE) begin
         case (trans.addr)
            32'h4000_2000: apb_lcr_queue.push_back(trans);
            32'h4000_2004: apb_dlr_queue.push_back(trans);
            32'h4000_2010: begin
               apb_tx_queue.push_back(trans);
               tx_count = tx_count +1;
            end
         endcase
      end
      else if (trans.xact_type == apb_transaction::READ) begin
         if (trans.addr == 32'h4000_200C) 
            apb_fsr_queue.push_back(trans);
         if (trans.addr == 32'h4000_2014)
            apb_rx_queue.push_back(trans);
         if (trans.addr >= 32'h4000_2018 && trans.addr <= 32'h4000_2FFF) begin
            apb_rsvd_queue.push_back(trans);
            check_rsvd();
         end
      end
      `uvm_info("run_phase", $sformatf("Get transaction from monitor: \n%s", trans.sprint()), UVM_LOW)
   endfunction

   function void check_TX_data();
      while (apb_tx_queue.size()>0 && spi_mosi_queue.size()>0) begin
         apb_tx_trans   = apb_tx_queue.pop_front();
         spi_mosi_trans = spi_mosi_queue.pop_front();

         `uvm_info(get_type_name(), $sformatf("Ckecking transfer data"), UVM_LOW)

         tbr_data = 0;
         case(cfg.word)
            8  : tbr_data[7:0]   = apb_tx_trans.data[7:0];
            16 : tbr_data[15:0]  = apb_tx_trans.data[15:0];
            default: `uvm_error(get_type_name(), $sformatf("Error word frame: %d", cfg.word))
         endcase

         if (tbr_data != spi_mosi_trans.data)
            `uvm_error(get_type_name(), $sformatf("Data transfer from dut to spi slaver mismatch"))

         `uvm_info(get_type_name(), $sformatf("Check transfer data done"), UVM_LOW)
      end
   endfunction

      function void check_RX_data();
         while (apb_rx_queue.size()>0 && spi_miso_queue.size()>0) begin
            apb_rx_trans   = apb_rx_queue.pop_front();
            spi_miso_trans = spi_miso_queue.pop_front();

            `uvm_info(get_type_name(), $sformatf("Checking receive data"), UVM_LOW)

            if (apb_rx_trans.data != spi_miso_trans.data)
               `uvm_error(get_type_name(), $sformatf("Data receive from slaver to dut mismatch"))

            `uvm_info(get_type_name(), $sformatf("Check receive data DONE"), UVM_LOW)
         end
      endfunction

   function void check_ss();
      bit [1:0] slaver_id = 2'b0;
      
      while(ss_queue.size()>0) begin
         ss = ss_queue.pop_front();
         ss_count = ss_count + 1;
         `uvm_info(get_type_name(), $sformatf("Check slaver select"), UVM_LOW)
         case (ss)
            4'b1110: slaver_id = 2'd0;
            4'b1101: slaver_id = 2'd1;
            4'b1011: slaver_id = 2'd2;
            4'b0111: slaver_id = 2'd3;
            default: `uvm_error(get_type_name(), $sformatf("Slaver select error- slave: %0b", ss))
         endcase

         if (slaver_id != apb_lcr_trans.data[5:4])
            `uvm_error(get_type_name(), $sformatf("Slaver select mismatch with LCR"))
         if (slaver_id != cfg.slave_id)
            `uvm_error(get_type_name(), $sformatf("Slaver select mismatch with spi_configuration"))
         `uvm_info(get_type_name(), "Cleck slaver select DONE", UVM_LOW)
      end
		
		`uvm_info(get_type_name(), $sformatf("Number of SS changes state: %0d", ss_count), UVM_LOW)
      if (cfg.cdte) begin
         if (tx_count > 0 && ss_count != 1)
            `uvm_error(get_type_name(), $sformatf("The DUT released SS during continuous mode"))
      end
      	else 
         	if (tx_count != ss_count)
         		`uvm_error(get_type_name(), $sformatf("The DUT released SS mismatch during non continuous mode"))
   endfunction
   
   function void check_sclk_freq();
   		int setup_freq;
   		while(sclk_freq_queue.size()>0) begin
   			sclk_freq = sclk_freq_queue.pop_front();
   			setup_freq = (apb_freq.freq*1_000_000)/(2*(cfg.div_val+1));
   			if (sclk_freq != setup_freq)
   				`uvm_error(get_type_name(), $sformatf("SCLK freq mismach: SCLK = %0dHz, setup SCLK = %0dHz", sclk_freq, setup_freq))
   		end
   		`uvm_info(get_type_name(), $sformatf("Exiting sclk check"), UVM_LOW)
   		`uvm_info(get_type_name(), $sformatf("=============================================="), UVM_LOW)
   		`uvm_info(get_type_name(), $sformatf("=                SCLK = %0dHz            =", sclk_freq), UVM_LOW)
   		`uvm_info(get_type_name(), $sformatf("=============================================="), UVM_LOW)
   	endfunction
	

   function void compare();
		ss_count = 0;
      while (apb_lcr_queue.size()>0)
      		apb_lcr_trans = apb_lcr_queue.pop_front();
      fork
         	check_TX_data();
         	check_RX_data();
         	check_ss();
         	check_sclk_freq();
      	join
   endfunction

   function void check_rsvd();
      while(apb_rsvd_queue.size()>0) begin
         apb_rsvd_trans = apb_rsvd_queue.pop_front();
         if(apb_rsvd_trans.data != 32'hFFFF_FFFF)
            `uvm_error(get_type_name(), "Rsvd value mismatch with spec")
         if(apb_rsvd_trans.pslverr == 0)
            `uvm_error(get_type_name(), "Rsvd not give response")
      end
   endfunction
   
	function void sample_spi_fc(spi_configuration cfg, apb_configuration apb_freq);
		$cast(coverage_cfg, cfg);
      $cast(coverage_apb_freq, apb_freq);
		SPI_COVERGROUP.sample();
	endfunction

endclass
