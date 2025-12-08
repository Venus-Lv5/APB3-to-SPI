class spi_monitor extends uvm_monitor;
   `uvm_component_utils(spi_monitor);

   int half_bit;
   virtual spi_if spi_vif;
   virtual apb_if apb_vif;
   spi_configuration cfg;
   
   event miso_capture_done;
   event mosi_capture_done;

   uvm_analysis_port #(spi_transaction) spi_observe_port_mosi;
   uvm_analysis_port #(spi_transaction) spi_observe_port_miso;
   uvm_analysis_port #(bit [3:0])       spi_observe_port_ss;

   function new(string name = "spi_monitor", uvm_component parent);
      super.new(name, parent);
      spi_observe_port_mosi = new("spi_obverse_port_mosi", this);
      spi_observe_port_miso = new("spi_observe_port_miso", this);
      spi_observe_port_ss   = new("spi_observe_port_ss",   this);
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
   endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
      fork
         capture_mosi();
         capture_miso();
         check_freq();
         capture_ss(); 
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

            if(cfg.cpha ^ cfg.cpol)
               @(negedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
            else
               @(posedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);

            if(spi_vif.SS[cfg.slave_id])
               break;

            data[cfg.word-1] = spi_vif.MOSI;
            for(bit_idx = 1; bit_idx < cfg.word && !spi_vif.SS[cfg.slave_id]; bit_idx++) begin
               if(cfg.cpha ^ cfg.cpol)
                  @(negedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
               else
                  @(posedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
               if(spi_vif.SS[cfg.slave_id])
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
         @(posedge spi_vif.SS[cfg.slave_id]);
      end
   endtask

   task capture_miso();
      spi_transaction tr;
      bit [15:0] data;
      int bit_idx;
      forever begin
         wait(spi_vif.SS != 4'b1111);
         while(!spi_vif.SS[cfg.slave_id]) begin
            data = '0;
            if(cfg.cpha ^ cfg.cpol)
               @(negedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
            else
               @(posedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
            if(spi_vif.SS[cfg.slave_id])
               break;
            data[cfg.word-1] = spi_vif.MISO;

            for(bit_idx = 1; bit_idx < cfg.word && !spi_vif.SS[cfg.slave_id]; bit_idx++) begin
               if(cfg.cpha ^ cfg.cpol)
                  @(negedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
               else
                  @(posedge spi_vif.SCLK or posedge spi_vif.SS[cfg.slave_id]);
               if(spi_vif.SS[cfg.slave_id])
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
         @(posedge spi_vif.SS[cfg.slave_id]);
      end
   endtask
   
   task check_freq();
      time t0;
      time t1;

      if(cfg.mode != spi_configuration::MASTER)
         disable check_freq;

      forever begin
         @(posedge spi_vif.SCLK);
         t0 = $time;
         @(posedge spi_vif.SCLK);
         t1 = $time;
         if(half_bit > 0) begin
            if((t1 - t0) != half_bit*2)
            `uvm_info(get_type_name(), $sformatf("Actual period is: %0dns, Expected period is: %0dns", t1-t0, half_bit*2), UVM_LOW)
         end
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

endclass
