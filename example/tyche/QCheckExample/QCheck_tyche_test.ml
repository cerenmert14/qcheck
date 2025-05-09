let size_int l = QCheck2.Test.Int (List.length l)

let size_float l = QCheck2.Test.Float (float_of_int (List.length l))
let passing =
  QCheck2.(Test.make ~count:100
            ~name:"list_rev_is_involutive"
            ~print:Print.(list int)
            ~features: [("size_int", size_int); ("size_float", size_float)]
            Gen.(list int)
            (fun l -> List.rev (List.rev l) = l))
let failing =
  QCheck2.(Test.make ~count:10
            ~name:"should_fail_sort_id"
            ~print:Print.(list int)
            Gen.(list int)
    (fun l -> l = List.sort compare l))

exception Error

let num_size n = string_of_int (String.length (string_of_int n))
let error =
  QCheck2.(Test.make ~count:10
            ~name:"should_error_raise_exn"
            ~print:Print.(int)
            ~collect:num_size
            Gen.(int)
    (fun _ -> raise Error))

let collect =
  QCheck2.(Test.make ~count:100
          ~long_factor:100
          ~name:"collect_results"
          ~print:Print.(int)
          ~collect:num_size
          (Gen.int_bound 4)
          (fun _ -> true))    

let stats =
  QCheck2.(Test.make ~count:100 
              ~long_factor:100
              ~name:"with_stats"
              ~print:Print.(int)
              ~collect:num_size
              (Gen.int_bound 120)
              ~stats:[
                "mod4", (fun i->i mod 4);
                "num", (fun i->i);
              ]
            (fun _ -> true))
let neg_test_failing_as_expected =
  QCheck2.(Test.make_neg ~name:"neg test pass (failing as expected)" 
            ~print:Print.(int)
            ~collect:num_size
            Gen.small_int 
            (fun i -> i mod 2 = 0))
 

let neg_test_unexpected_success =
  QCheck2.(Test.make_neg ~name:"neg test unexpected success" 
              ~print:Print.(int)
              ~collect:num_size
              Gen.small_int 
              (fun i -> i + i = i * 2))

let neg_test_error =
  QCheck2.(Test.make_neg ~name:"neg fail with error" 
              ~print:Print.(int)
              ~collect:num_size
              Gen.small_int  
              (fun _i -> raise Error))
let fun1 =
  QCheck2.(Test.make ~count:100 ~long_factor:100
          ~name:"FAIL_pred_map_commute"
          (Gen.triple
              (Gen.small_list (Gen.small_int))
              (fun1 Observable.int Gen.int)
              (fun1 Observable.int Gen.bool))
          (fun (l,QCheck2.Fun (_,f), QCheck2.Fun (_,p)) ->
              List.filter p (List.map f l) = List.map f (List.filter p l)))

let fun2 =
  QCheck2.(Test.make ~count:100
        ~name:"FAIL_fun2_pred_strings"
        (fun1 Observable.string Gen.bool)
        (fun (QCheck2.Fun (_,p)) ->
          not (p "some random string") || p "some other string"))

let bad_assume_warn =
  QCheck2.(Test.make ~count:2_000
              ~name:"WARN_unlikely_precond"
              ~print:Print.(int)
              ~collect:num_size
              Gen.int
              (fun x ->
                QCheck.assume (x mod 100 = 1);
                true))

let bad_assume_fail =
  QCheck2.(Test.make ~count:2_000 ~if_assumptions_fail:(`Fatal, 0.1)
            ~name:"FAIL_unlikely_precond"
            ~print:Print.(int)
            ~collect:num_size
            Gen.int
            (fun x -> QCheck2.assume (x mod 100 = 1);
              true))

let int_gen = QCheck2.Gen.small_int

(* Another example (false) property *)
let prop_foldleft_foldright =
  QCheck2.(Test.make ~name:"fold_left fold_right" 
                    ~count:1000 
                    ~long_factor:20
                    (Gen.triple
                      int_gen
                      (Gen.list int_gen)
                      (fun2 Observable.int Observable.int int_gen))
                    (fun (z,xs,f) ->
                      let l1 = List.fold_right (Fn.apply f) xs z in
                      let l2 = List.fold_left (Fn.apply f) z xs in
                      if l1=l2 then true
                      else QCheck2.Test.fail_reportf "l=%s, fold_left=%s, fold_right=%s@."
                          (QCheck2.Print.(list int) xs)
                          (QCheck2.Print.int l1)
                          (QCheck2.Print.int l2)
                    ))

(* Another example (false) property *)
let prop_foldleft_foldright_uncurry =
  QCheck2.(Test.make ~name:"fold_left fold_right uncurried" 
                    ~count:1000 ~long_factor:20
                  (Gen.triple
                    (fun1 Observable.(pair int int) int_gen)
                      int_gen
                    (Gen.list int_gen))
                  (fun (f,z,xs) ->
                    List.fold_right (fun x y -> Fn.apply f (x,y)) xs z =
                    List.fold_left (fun x y -> Fn.apply f (x,y)) z xs))

let long_shrink =
  let listgen = QCheck2.Gen.list_size (QCheck2.Gen.int_range 1000 10000) QCheck2.Gen.int in
  QCheck2.(Test.make ~name:"long_shrink"
            (Gen.pair listgen listgen)
          (fun (xs,ys) -> List.rev (xs@ys) = (List.rev xs)@(List.rev ys)))

let find_ex =
  let open QCheck in
  Test.make ~name:"find_example" (2--50)
  (fun n ->
    let st = Random.State.make [| 0 |] in
    let f m = n < m && m < 2 * n in
    try
      let m = find_example_gen ~rand:st ~count:100_000 ~f Gen.(0 -- 1000) in
      f m
     with No_example_found _ -> false)

let find_ex_uncaught_issue_99 : _ list =
  let open QCheck in
  let t1 =
    let rs = make (find_example ~count:10 ~f:(fun _ -> false) Gen.int) in
    Test.make ~name:"FAIL_#99_1" rs (fun _ -> true) in
  let t2 =
    Test.make ~name:"should_succeed_#99_2" ~count:10 int
      (fun i -> i <= max_int) in
  [t1;t2]

(* test shrinking on integers *)
let shrink_int =
  QCheck2.(Test.make ~count:1000 ~name:"mod3_should_fail"
                    ~print:Print.(int) ~collect:string_of_int        
                Gen.int (fun i -> i mod 3 <> 0))

let stats_negs =
  QCheck.(Test.make ~count:5_000 ~name:"stats_neg"
      (add_stat ("dist",fun x -> x) small_signed_int))
    (fun _ -> true)

type tree = Leaf of int | Node of tree * tree

let leaf x = Leaf x
let node x y = Node (x,y)
let gen_tree = QCheck2.Gen.(sized @@ fix
  (fun self n -> match n with
    | 0 -> map leaf nat
    | n ->
      frequency
        [1, map leaf nat;
         2, map2 node (self (n/2)) (self (n/2))]
    ))

let rec rev_tree = function
  | Node (x, y) -> Node (rev_tree y, rev_tree x)
  | Leaf x -> Leaf x

let passing_tree_rev =
  QCheck2.(Test.make ~count:1000
    ~name:"tree_rev_is_involutive"
    gen_tree
    (fun tree -> rev_tree (rev_tree tree) = tree))


let stats_tests =
  let open QCheck in
  [
    Test.make ~name:"stat_display_test_1" ~count:1000 (add_stat ("dist",fun x -> x) small_signed_int) (fun _ -> true);
    Test.make ~name:"stat_display_test_2" ~count:1000 (add_stat ("dist",fun x -> x) small_nat) (fun _ -> true);
    Test.make ~name:"stat_display_test_3" ~count:1000 (add_stat ("dist",fun x -> x) (int_range (-43643) 435434)) (fun _ -> true);
    Test.make ~name:"stat_display_test_4" ~count:1000 (add_stat ("dist",fun x -> x) (int_range (-40000) 40000)) (fun _ -> true);
    Test.make ~name:"stat_display_test_5" ~count:1000 (add_stat ("dist",fun x -> x) (int_range (-4) 4)) (fun _ -> true);
    Test.make ~name:"stat_display_test_6" ~count:1000 (add_stat ("dist",fun x -> x) (int_range (-4) 17)) (fun _ -> true);
    Test.make ~name:"stat_display_test_7" ~count:100000 (add_stat ("dist",fun x -> x) int) (fun _ -> true);
  ]

let () =
  QCheck_tyche.run_tests_main ([
    passing;
    failing;
    error;
    collect;
    stats; 
    neg_test_failing_as_expected;
    neg_test_unexpected_success;
    neg_test_error;
    fun1;
    fun2;
    prop_foldleft_foldright;
    prop_foldleft_foldright_uncurry;
    long_shrink; 
    find_ex;
    shrink_int;
    stats_negs;
    bad_assume_warn;
    bad_assume_fail;
    passing_tree_rev;
 ] @ find_ex_uncaught_issue_99) 

