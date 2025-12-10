class spi_driver extends uvm_driver #(spi_transaction);
   `uvm_component_utils(spi_driver);

   virtual spi_if    spi_vif;
   spi_configuration cfg;
   int               half_bit;

   function new(string name = "spi_driver", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if(!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get spi_vif from uvm_config_db"))
      if(!uvm_config_db#(spi_configuration)::get(this, "", "cfg", cfg))
         `uvm_fatal(get_type_name(), $sformatf("Failed to get spi_configuration from uvm_config_db"))
         
      half_bit = 1_000_000_000/(2*cfg.freq);
   endfunction : build_phase

   virtual task run_phase(uvm_phase phase);
   		spi_transaction   req, rsp;
 
      case (cfg.mode)
         spi_configuration::MASTER: master_drive();
         spi_configuration::SLAVE: slave_drive();
         default : `uvm_error("spi_driver", "Unknow mode")
      endcase
   endtask : run_phase

   task master_drive();
   		req = spi_transaction::type_id::create("req", this);
      spi_vif.SCLK   = cfg.cpol;
      spi_vif.SS     = 4'b1111;

      forever begin
         seq_item_port.get_next_item(req);
         $cast(rsp, req.clone());

         spi_vif.SCLK               = cfg.cpol;
         spi_vif.SS[cfg.slave_id]  = 1'b0;

         fork
            master_drive_sclk();
            drive_port(req, spi_vif.MOSI);
         join

         if ((!cfg.cdte || is_frame_end(req.data)) && !spi_vif.SS[cfg.slave_id]) begin
            repeat (cfg.cpha + 1) #(half_bit*1ns);
            spi_vif.SS[cfg.slave_id] = 1'b1;
            #(half_bit*4*1ns);
         end
      rsp.set_id_info(req);
      seq_item_port.put(rsp);
      seq_item_port.item_done();
      end
   endtask: master_drive

   function bit is_frame_end(bit [15:0] data);
      if(cfg.word == 8)
         return (data[7:0] == 8'hFF);
      else 
         return (data[15:0] == 16'hFFFF);
   endfunction

   task slave_drive();
      req = spi_transaction::type_id::create("req", this);
      forever begin
         seq_item_port.get_next_item(req);
         $cast(rsp, req.clone());
         wait(spi_vif.SS != 4'b1111);
         drive_port(req, spi_vif.MISO);
         rsp.set_id_info(req);
       	seq_item_port.put(rsp);
       	seq_item_port.item_done();
      end
   endtask

   task master_drive_sclk();
      if(!cfg.cdte)
         #(half_bit*1ns);

      for (int i = 0; i < cfg.word*2 && !spi_vif.SS[cfg.slave_id]; i++) begin
          #(half_bit*1ns);
         if(!spi_vif.SS[cfg.slave_id])
            spi_vif.SCLK = ~spi_vif.SCLK;
      end
   endtask
   
   task drive_port(input spi_transaction req, ref logic port);
      case({cfg.cpha,cfg.cpol})
         2'b00: drive_cpha0_cpol0(req, port);
         2'b01: drive_cpha0_cpol1(req, port);
         2'b10: drive_cpha1_cpol0(req, port);
         2'b11: drive_cpha1_cpol1(req, port);
      endcase  
   endtask

	task drive_cpha0_cpol0(input spi_transaction req, ref logic port);
		int i;
		port = req.data[cfg.word-1];
		for (i = 1; i < cfg.word && spi_vif.SS != 4'b1111; i++) begin
		   @(negedge spi_vif.SCLK or spi_vif.SS == 4'b1111);
		   if (spi_vif.SS == 4'b1111) break;
		   port = req.data[cfg.word-1-i];
		end
	endtask


	task drive_cpha0_cpol1(input spi_transaction req, ref logic port);
		int i;
		port = req.data[cfg.word-1];
		for (i = 1; i < cfg.word && spi_vif.SS != 4'b1111; i++) begin
		   @(posedge spi_vif.SCLK or spi_vif.SS == 4'b1111);
		   if (spi_vif.SS == 4'b1111) break;
		   port = req.data[cfg.word-1-i];
		end
	endtask


	task drive_cpha1_cpol0(input spi_transaction req, ref logic port);
		int i;
		for (i = 0; i < cfg.word && spi_vif.SS != 4'b1111; i++) begin
		   @(posedge spi_vif.SCLK or spi_vif.SS == 4'b1111);
		   if (spi_vif.SS == 4'b1111) break;
		   port = req.data[cfg.word-1-i];
		end
	endtask


	task drive_cpha1_cpol1(input spi_transaction req, ref logic port);
		int i;
		for (i = 0; i < cfg.word && spi_vif.SS != 4'b1111; i++) begin
		   @(negedge spi_vif.SCLK or spi_vif.SS == 4'b1111);
		   if (spi_vif.SS == 4'b1111) break;
		   port = req.data[cfg.word-1-i];
		end

	endtask


endclass
