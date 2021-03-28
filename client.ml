(* Tries to open a connection to a socket listening at addr:port.
   Returns Some(sock) if successful, None otherwise. *)
let try_sock_connect addr port =
  let sock = Unix.socket PF_INET SOCK_STREAM 0 in
  let sock_addr =
    Unix.ADDR_INET (Unix.inet_addr_of_string addr, port)
  in
  try
    Unix.connect sock sock_addr;
    Some sock
  with Unix.Unix_error _ -> None

(* Client update loop. Pulls data from the server, and sticks it in the
   shared mutable state. *)
let client_loop ((sock, state) : Unix.file_descr * Common.world_state) =
  let recv_chan = Unix.in_channel_of_descr sock in
  while true do
    let noveau =
      (Marshal.from_channel recv_chan : Common.entity option array)
    in
    let first = noveau.(0) |> Option.get in
    string_of_float first.x ^ string_of_float first.y |> print_endline;
    let len = Array.length noveau in
    Mutex.lock state.mutex;
    Array.blit noveau 0 state.data 0 len;
    Mutex.unlock state.mutex
  done

(* This initializes the shared state, and then spins up the new thread
   for the client to be on. *)
let start addr port =
  let state : Common.world_state =
    {
      data = Array.make 500 None;
      mutex = Mutex.create ();
      highest_uuid = ref 0;
    }
  in
  match try_sock_connect addr port with
  | Some sock -> Some (state, Thread.create client_loop (sock, state))
  | None -> None
