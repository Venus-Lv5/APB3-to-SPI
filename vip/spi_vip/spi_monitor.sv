class spi_monitor extends uvm_monitor;
   `uvm_component_utils(spi_monitor);

   int half_bit;
   bit cnt_en;
   virtual spi_if spi_vif;
   virtual apb_if apb_vif;
   spi_configuration cfg;
   
   event miso_capture_done;
   event mosi_capture_done;
   event mosi_capture_start;
   event frame_done;

   uvm_analysis_port #(spi_transaction) spi_observe_port_mosi;
   uvm_analysis_port #(spi_transaction) spi_observe_port_miso;
   uvm_analysis_port #(bit [3:0])       spi_observe_port_ss;
   uvm_analysis_port #(int)         spi_observe_port_sclk_freq;

   function new(string name = "spi_monitor", uvm_component parent);
      super.new(name, parent);
      spi_observe_port_mosi = new("spi_obverse_port_mosi", this);
      spi_observe_port_miso = new("spi_observe_port_miso", this);
      spi_observe_port_ss   = new("spi_observe_port_ss",   this);
      spi_observe_port_sclk_freq = new("spi_observe_port_sclk_freq", this);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual spi_if)::get(this,"","spi_vif",spi_vif))
         `uvm_fatal(get_type_name(),"Failed to get spi_vif from uvm_config_db")
      if(!uvm_config_db#(virtual apb_if)::get(this,"","apb_vif",apb_vif))
         `uvm_fatal(get_type_name(),"Failed to get apb_vif from uvm_config_db")  
      if(!uvm_config_db#(spi_configuration)::get(this,"","cfg",cfg))
         `uvm_fatal(get_type_name(),"Failed to get cfg from uvm_config_db")
      if(cfg.mode == spi_configuration::MASTER)
         half_bit = 1_000_000_000 / (2 * cfg.freq);   
         
      cnt_en = 1;
   endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
      fork
         capture_mosi();
         capture_miso();
         capture_ss(); 
         if (cnt_en)
            check_freq();
         if (cnt_en)
         		count_edge();
      join
   endtask : run_phase


   task capture_mosi();
      spi_transaction tr;
      bit [15:0] data;
      int bit_idx;
      forever begin
         wait(spi_vif.SS != 4'b1111);
         while(spi_vif.SS != 4'b1111) begin
            data = '0;
				->mosi_capture_start;
            if(cfg.cpha ^ cfg.cpol)
               @(negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
            else
               @(posedge spi_vif.SCLK or spi_vif.SS ==4'b1111);

            if(spi_vif.SS ==4'b1111)
               break;

            data[cfg.word-1] = spi_vif.MOSI;
            for(bit_idx = 1; bit_idx < cfg.word && spi_vif.SS !=4'b1111; bit_idx++) begin
               if(cfg.cpha ^ cfg.cpol)
                  @(negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
               else
                  @(posedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
               if(spi_vif.SS ==4'b1111)
                  break;
               data[cfg.word-1-bit_idx] = spi_vif.MOSI;
            end
            tr = spi_transaction::type_id::create("tr_mosi", this);
            tr.data = data;
            spi_observe_port_mosi.write(tr);
            -> mosi_capture_done;
              if(!cfg.cdte)
               break;
         end
         @(spi_vif.SS ==4'b1111);
      end
   endtask

   task capture_miso();
      spi_transaction tr;
      bit [15:0] data;
      int bit_idx;
      forever begin
         wait(spi_vif.SS != 4'b1111);
         while(spi_vif.SS !=4'b1111) begin
            data = '0;
            if(cfg.cpha ^ cfg.cpol)
               @(negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
            else
               @(posedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
            if(spi_vif.SS ==4'b1111)
               break;
            data[cfg.word-1] = spi_vif.MISO;

            for(bit_idx = 1; bit_idx < cfg.word && spi_vif.SS !=4'b1111; bit_idx++) begin
               if(cfg.cpha ^ cfg.cpol)
                  @(negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
               else
                  @(posedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
               if(spi_vif.SS ==4'b1111)
                  break;
               data[cfg.word-1-bit_idx] = spi_vif.MISO;
            end

            tr = spi_transaction::type_id::create("tr_miso", this);
            tr.data = data;
            spi_observe_port_miso.write(tr);
				-> miso_capture_done;
            if(!cfg.cdte )
               break;
         end
         @(spi_vif.SS ==4'b1111);
      end
   endtask
   
	task automatic check_freq();
		time t_first;
		time t_last;
		int  edge_cnt;
		int  sample_edges;

		forever begin
		   wait(spi_vif.SS != 4'b1111);

		   t_first      = 0;
		   t_last       = 0;
		   edge_cnt     = 0;
		   sample_edges = cfg.word;

		   while (edge_cnt < sample_edges) begin
		      if (cfg.cpha ^ cfg.cpol)
		         @(negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
		      else
		         @(posedge spi_vif.SCLK or spi_vif.SS ==4'b1111);

		      if (spi_vif.SS ==4'b1111)
		         break;

		      if (edge_cnt == 0)
		         t_first = $time;

		      t_last = $time;
		      edge_cnt++;
		   end
		   if (edge_cnt >= 2 && t_last > t_first) begin
		      longint freq_hz = ((edge_cnt - 1) * 1000000000) / (t_last - t_first);
		      spi_observe_port_sclk_freq.write(freq_hz);
		   end
		end
	endtask
	
	task automatic count_edge();
		int  edge_cnt;
		int  sample_edges;

		forever begin
		   wait(spi_vif.SS != 4'b1111);
		   edge_cnt     = 0;
		   sample_edges = cfg.word *2;

		   while (edge_cnt < sample_edges) begin
		      @(posedge spi_vif.SCLK or negedge spi_vif.SCLK or spi_vif.SS ==4'b1111);
		      if (spi_vif.SS ==4'b1111)
		         break;
		      edge_cnt++;
		   end
		   if(edge_cnt == sample_edges)
				-> frame_done;
		end
	endtask

   
   task capture_ss();
      bit [3:0] ss_val = 4'b1111;
      bit [3:0] pre_ss_val = 4'b1111;

      wait(apb_vif.PRESETn == 1);
      forever begin
      		@(posedge apb_vif.PCLK or negedge apb_vif.PCLK);
      		ss_val = spi_vif.SS;
         if(pre_ss_val != ss_val) begin
         		pre_ss_val = ss_val;
         		if (ss_val != 4'b1111)
         			spi_observe_port_ss.write(ss_val);
         	end
      end
   endtask
   
   function void dis_cnt_edge();
   		cnt_en = 0;
   	endfunction

endclass
