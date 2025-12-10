spi_configuration coverage_cfg;
apb_configuration coverage_apb_freq;
covergroup SPI_COVERGROUP;

	PCLK : coverpoint coverage_apb_freq.freq{
		bins PCLK[] = {20, 50, 100};
	}


	data_width : coverpoint coverage_cfg.word{
		bins data_width[] = {8,16};
	}

	cpol : coverpoint coverage_cfg.cpol{
		bins cpol[] = {0, 1};
	}

	cpha : coverpoint coverage_cfg.cpha{
		bins cpha[] = {0, 1};
	}

   countinous_mode : coverpoint coverage_cfg.cdte{
      bins countinous_mode[] = {0, 1};
   }

   slave_id : coverpoint coverage_cfg.slave_id{
      bins slave_id[] = {[0:3]};
   }


	word_cpol_cpha_cdte_slave : cross data_width, cpol, cpha, countinous_mode, slave_id;
endgroup
