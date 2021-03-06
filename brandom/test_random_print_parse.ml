open Blib

let dump_string (i:int) (str:string) : unit =
  let out = open_out ("dump_test_" ^ string_of_int i) in
  let _ = Printf.fprintf out "%s" str in
  close_out out

let dump_component (i:int) (c:PSyntax.component) (j:int) : unit =
  let out1 = open_out ("dump_test_" ^ string_of_int i ^ "_" ^ string_of_int j ) in
  let sexp1 = Sexp.sexp_of_component c in
  let _ = Printf.fprintf out1 "%s" (Sexp.sexp_to_string sexp1) in
  close_out out1

let print_and_parse (c:PSyntax.component) : (PSyntax.component*string) =
  let str = Print.component_to_string c in
  let c = Parser.parse_component_from_string str in
  (c,str)

let nb_of_tests = 10

let run () = 
  let st = Random.get_state () in
  for i=1 to nb_of_tests do
    let c  = Generators.gen_component st in
    let (c2,ef) = print_and_parse c in
    if PSyntax.equal_component c c2 then
      print_endline "Success"
    else
      begin
        dump_component i c 1;
        dump_component i c2 2;
        Printf.fprintf (open_out ("c_dump_"^string_of_int i)) "%s" ef;
        print_endline "Failure"
      end
  done

let () =
  try
    Random.self_init ();
    run ()
  with
    Error.Fatal ->
    print_endline "Fatal error";
    exit(1)
