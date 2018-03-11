let continue_on_error = ref false
let out = ref stdout

let set_out s =
  out := open_out s

let print_error err =
  Error.print_error err;
  if not !continue_on_error then exit(1)

let print_error_no_loc msg =
  Printf.fprintf stderr "%s\n" msg;
  if not !continue_on_error then exit(1)

let run_on_file filename =
  try
    let input = open_in filename in
    match Parser.parse_component filename input with
    | Ok c -> Print.print_component !out c
    | Error err -> print_error err
  with
  | Sys_error msg -> print_error_no_loc msg

let add_path s =
  match File.add_path s with
  | Ok _ -> ()
  | Error err -> print_error_no_loc err

let args = [
  ("-c", Arg.Set continue_on_error, "Continue on error" );
  ("-o", Arg.String set_out, "Output file" );
  ("-I", Arg.String add_path, "Path for definitions files" );
  ("-f", Arg.Int Lexer.set_macro_fuel, "Max number of definition expansions for one file (default is 999)." );
]

let _ = Arg.parse args run_on_file ("Usage: "^ Sys.argv.(0) ^" [options] files")
