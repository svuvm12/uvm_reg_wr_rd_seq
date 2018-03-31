// Code your testbench here
// or browse Examples

class uvm_single_reg_field_wr_rd_seq extends uvm_reg_sequence #(uvm_sequence #(uvm_reg_item));
  
   // Variable: rg
   // The register to be tested
   uvm_reg rg;

   `uvm_object_utils(uvm_single_reg_field_wr_rd_seq)

   function new(string name="uvm_single_reg_field_wr_rd_seq");
     super.new(name);
   endfunction

   virtual task body();
      uvm_reg_field fields[$];
      string mode[`UVM_REG_DATA_WIDTH];
      uvm_reg_map maps[$];
      uvm_reg_data_t  dc_mask;
      uvm_reg_data_t  reset_val,wdata_f,reg_data,rdata;
      int n_bits;
         
      if (rg == null) begin
         `uvm_error("uvm_single_reg_field_wr_rd_seq", "No register specified to run sequence on");
         return;
      end

      // Registers with some attributes are not to be tested
      if (uvm_resource_db#(bit)::get_by_name({"REG::",rg.get_full_name()},
                                             "NO_REG_TESTS", 0) != null ||
          uvm_resource_db#(bit)::get_by_name({"REG::",rg.get_full_name()},
                                             "NO_REG_BIT_BASH_TEST", 0) != null )
            return;
      
      n_bits = rg.get_n_bytes() * 8;
         
      // Let's see what kind of bits we have...
      rg.get_fields(fields);
         
      // Registers may be accessible from multiple physical interfaces (maps)
      rg.get_maps(maps);
         
      foreach (maps[j]) begin
         uvm_status_e status;
         uvm_reg_data_t  val, exp, v;
         int next_lsb;
         
         next_lsb = 0;
         dc_mask  = 0;
         
        
        reg_data = rg.get(); 
        
        // First Write to all fields
   
        foreach (fields[k]) begin 
           int lsb, w, dc; 
           
           lsb = fields[k].get_lsb_pos();
           w   = fields[k].get_n_bits();
           
           if(k%2 == 0) 
              wdata_f = '1;
           else
              wdata_f = '0; 
          
           for(int h=0;h<w;h++) begin
             reg_data[lsb+h] = wdata_f[h];
           end  
        end   
        
        rg.write(.status(status),.value(reg_data),.parent(this));
        
        rg.read(.status(status),.value(rdata),.parent(this));
        
        foreach (fields[k]) begin 
          if(fields[k].get_access == "RW") begin
            int lsb, w, dc; 
           
            lsb = fields[k].get_lsb_pos();
            w   = fields[k].get_n_bits(); 
           
            if(k%2 == 0) begin 
              for(int h=0;h<w;h++) begin  
                if(rdata[lsb+h] != 1'b1) begin
                  `uvm_error(get_full_name(),$sformatf("Read Data %0h does not match with Expected Data 1'b1 for bit %0d !!",rdata[lsb+h],lsb+h))
                 end
              end   
            end
            else begin
              for(int h=0;h<w;h++) begin  
                if(rdata[lsb+h] != 1'b0) begin
                  `uvm_error(get_full_name(),$sformatf("Read Data %0h does not match with Expected Data 1'b0  for bit %0d !!",rdata[lsb+h],lsb+h))
                 end
              end
            end   
          end   
        end
         // Any unused bits on the left side of the MSB?
        while (next_lsb < `UVM_REG_DATA_WIDTH)
            mode[next_lsb++] = "RO";
         
         `uvm_info("uvm_reg_bit_bash_seq", $sformatf("Verifying bits in register %s in map \"%s\"...",
                                    rg.get_full_name(), maps[j].get_full_name()),UVM_LOW);
         
            
      end
   endtask: body


endclass: uvm_single_reg_field_wr_rd_seq

class uvm_reg_wr_rd_seq extends uvm_reg_sequence #(uvm_sequence #(uvm_reg_item));

   // Variable: model
   //
   // The block to be tested. Declared in the base class.
   //
   //| uvm_reg_block model; 


   // Variable: reg_seq
   //
   // The sequence used to test one register
   //
   protected uvm_single_reg_field_wr_rd_seq reg_seq;
   
  `uvm_object_utils(uvm_reg_wr_rd_seq)

   function new(string name="uvm_reg_wr_rd_seq");
     super.new(name);
   endfunction


   // Task: body
   //
   // Executes the Register Bit Bash sequence.
   // Do not call directly. Use seq.start() instead.
   //
   virtual task body();
      
      if (model == null) begin
         `uvm_error("uvm_reg_wr_rd_seq", "No register model specified to run sequence on");
         return;
      end

      uvm_report_info("STARTING_SEQ",{"\n\nStarting ",get_name()," sequence...\n"},UVM_LOW);

     reg_seq = uvm_single_reg_field_wr_rd_seq::type_id::create("reg_single_field_wr_rd_seq");

      this.reset_blk(model);
      model.reset();

      do_block(model);
   endtask


   // Task: do_block
   //
   // Test all of the registers in a a given ~block~
   //
   protected virtual task do_block(uvm_reg_block blk);
      uvm_reg regs[$];

      if (uvm_resource_db#(bit)::get_by_name({"REG::",blk.get_full_name()},
                                             "NO_REG_TESTS", 0) != null ||
          uvm_resource_db#(bit)::get_by_name({"REG::",blk.get_full_name()},
                                             "NO_REG_FIELD_WRRD_TEST", 0) != null )
         return;

      // Iterate over all registers, checking accesses
      blk.get_registers(regs, UVM_NO_HIER);
      foreach (regs[i]) begin
         // Registers with some attributes are not to be tested
         if (uvm_resource_db#(bit)::get_by_name({"REG::",regs[i].get_full_name()},
                                                "NO_REG_TESTS", 0) != null ||
	     uvm_resource_db#(bit)::get_by_name({"REG::",regs[i].get_full_name()},
                                                "NO_REG_FIELD_WRRD_TEST", 0) != null )
            continue;
         
         reg_seq.rg = regs[i];
         reg_seq.start(null,this);
      end

      begin
         uvm_reg_block blks[$];
         
         blk.get_blocks(blks);
         foreach (blks[i]) begin
            do_block(blks[i]);
         end
      end
   endtask: do_block


   // Task: reset_blk
   //
   // Reset the DUT that corresponds to the specified block abstraction class.
   //
   // Currently empty.
   // Will rollback the environment's phase to the ~reset~
   // phase once the new phasing is available.
   //
   // In the meantime, the DUT should be reset before executing this
   // test sequence or this method should be implemented
   // in an extension to reset the DUT.
   //
   virtual task reset_blk(uvm_reg_block blk);
   endtask

endclass: uvm_reg_wr_rd_seq
