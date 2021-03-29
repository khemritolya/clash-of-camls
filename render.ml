let string_combiner graphic anim anim_frame =
  graphic ^ anim ^ string_of_int anim_frame ^ ".png"

let anim_decider right idle =
  (*this branch below is never called right now because there is no way
    of storing which way it was facing in previous frames before it
    stopped*)
  if right && idle then "_idle_right_"
  else if right && not idle then "_walk_right_"
  else if (not right) && idle then "_idle_left_"
  else if (not right) && not idle then "_walk_left_"
  else "error.png"

let string_helper (entity : Common.entity) right idle anim_frame =
  let main_graphic =
    List.hd (String.split_on_char '.' entity.graphic)
  in
  string_combiner main_graphic (anim_decider right idle) anim_frame

let image_getter_render
    (entity : Common.entity)
    hashmap
    screen
    anim_frame =
  let position_rect =
    Sdlvideo.rect (int_of_float entity.x) (int_of_float entity.y) 100
      100
  in
  let source =
    try
      Hashtbl.find hashmap
        (string_helper entity (entity.vx > 0.0)
           (entity.vx = 0.0 && entity.vy = 0.0)
           anim_frame)
    with Not_found -> Hashtbl.find hashmap "error.png"
  in
  Sdlvideo.blit_surface ~dst_rect:position_rect ~src:source ~dst:screen
    ()

(**[run] takes in world state and hashmap and renders the world map and
   every entity in world with the associated graphic in hashmap*)
let run (world_state : Common.world_state) hashmap =
  let start_time = Sdltimer.get_ticks () in
  let screen = Sdlvideo.set_video_mode 800 600 [ `DOUBLEBUF ] in
  while true do
    let world = World_manager.get_local world_state 400.0 300.0 in
    let map_position_rect = Sdlvideo.rect 0 0 100 100 in
    Sdlvideo.blit_surface ~dst_rect:map_position_rect
      ~src:(Hashtbl.find hashmap "map.png")
      ~dst:screen ();
    let time_begin = Sdltimer.get_ticks () in
    (*TODO unsync animations*)
    let anim_frame = (Sdltimer.get_ticks () - start_time) / 150 mod 4 in
    List.map
      (fun x -> image_getter_render x hashmap screen anim_frame)
      world
    |> ignore;
    Sdlvideo.flip screen;
    Input_handler.key_checker ();
    let time_end = Sdltimer.get_ticks () in
    Sdltimer.delay (max ((1000 / 60) - (time_end - time_begin)) 0)
  done
