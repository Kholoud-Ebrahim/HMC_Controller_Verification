typedef enum bit[1:0] { FIXED, INCR, WRAP } flit_type;
class my_sequence extends uvm_sequence ;
 my_transaction trans;
`uvm_object_utils(my_sequence)
 bit [10:0]  identier;
const int no_of_Wtrans;
flit_type f_type ;
function new(string name="my_sequence");
super.new(name);
endfunction
task body();
 repeat(no_of_Wtrans) begin
    identier++;
     trans = my_transaction::type_id::create("trans");
  start_item(trans);
  if(f_type == 0)
         assert(trans.randomize() with { f_type == FIXED; });
  else if(f_type == 1)
         assert(trans.randomize() with { f_type == INCR; });
  else if(f_type == 2)
         assert(trans.randomize() with { f_type == WRAP; });
  else
            assert(trans.randomize());
  finish_item(trans);
trans.TAG = {1'b0, identier};
 #10;
  end
   endtask
endclass
