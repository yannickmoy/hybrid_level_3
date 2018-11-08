package Hybrid_Level_3
  with SPARK_Mode
is

   type Train_ID is range 1 .. 50;
   type VSS_Index is range 1 .. 1000;
   type TTD_Index is range 1 .. 100;

   --  Types defining VSS data

   type VSS_State is --  3.2.1.2
      --  The trackside is certain that no train is located on the VSS.
     (Free,
      --  The trackside has information from a position report that an integer
      --  train is located on the VSS and the trackside is certain that no other
      --  vehicle is located in rear of this train on the same VSS.
      Occupied,
      --  The trackside has information from a position report that a train is
      --  located on the VSS and the trackside is NOT certain that no other
      --  vehicle is located in rear of this train on the same VSS.
      Ambiguous,
      --  The trackside has no information from a position report that a train
      --  is located on the VSS, but it is not certain that the VSS is free.
      Unknown);

   type VSS_Data is record
      State      : VSS_State;
      Inside_TTD : TTD_Index;
   end record;

   type VSS_On_Track is array (VSS_Index) of VSS_Data;

   --  Types defining TTD data

   subtype TTD_State is VSS_State range Free .. Occupied;

   type TTD_Data is record
      State                     : TTD_State;
      First_VSS                 : VSS_Index;
      Last_VSS                  : VSS_Index;
      Last_Train_Located_On_TTD : Train_ID;
   end record
     with Dynamic_Predicate => First_VSS <= Last_VSS;

   type TTD_On_Track is array (TTD_Index) of TTD_Data;

   type Track_Data is record
      VSS_View : VSS_On_Track;
      TTD_View : TTD_On_Track;
   end record
     with Dynamic_Predicate =>
       --  First VSS in TTD view is really first VSS
       TTD_View(TTD_Index'First).First_VSS = VSS_Index'First
       --  Last VSS in TTD view is really last VSS
       and then TTD_View(TTD_Index'Last).Last_VSS = VSS_Index'Last
       --  There is no gap in VSS when going from one TTD to the next
       and then (for all TTD in TTD_Index'First .. TTD_Index'Last - 1 =>
                   TTD_View(TTD).Last_VSS + 1 = TTD_View(TTD + 1).First_VSS)
       --  The cross-links between VSS and TTD are consistent
       and then (for all VSS in VSS_Index =>
                   VSS in TTD_View(VSS_View(VSS).Inside_TTD).First_VSS ..
                          TTD_View(VSS_View(VSS).Inside_TTD).Last_VSS);

   --  A TDD is Free iff all the corresponding VSS are Free
   function Valid_Track_Data (TD : Track_Data) return Boolean is
     (for all TDD in TTD_Index =>
        (TD.TTD_View (TDD).State = Free) =
        (for all VSS in TD.TTD_View (TDD).First_VSS ..
                        TD.TTD_View (TDD).Last_VSS =>
           TD.VSS_View (VSS).State = Free));

   --  Types defining the trains

   type Length is range 1 .. 10_000;

   type Train_Data is record
      Train_Length   : Length;
      Front_Position : TTD_Index;
   end record;

   type Trains_Data is array (Train_ID) of Train_Data;

   --  Global variables defining the state

   Track  : Track_Data;
   Trains : Trains_Data;

   --  Getters

   function State_Of (VSS : VSS_Index) return VSS_State is
      (Track.VSS_View(VSS).State);

   function State_Of (TTD : TTD_Index) return TTD_State is
      (Track.TTD_View(TTD).State);

   --  Events for state transitions

   type Event_Kind is
     (TTD_State_Event);

   type Event (Kind : Event_Kind) is record
      case Kind is
         when TTD_State_Event =>
            TTD   : TTD_Index;
            State : TTD_State;
      end case;
   end record;

   procedure State_Transition (E : Event; TTD : TTD_Index) with
     Pre  => Valid_Track_Data (Track),
     Post => Valid_Track_Data (Track),
     Contract_Cases =>
       (State_Of (TTD) = Free
        and then E.Kind = TTD_State_Event
        and then E.TTD = TTD
        and then E.State = Occupied
        => State_Of (TTD) = Occupied,

        State_Of (TTD) = Occupied
        and then E.Kind = TTD_State_Event
        and then E.TTD = TTD
        and then E.State = Free
        => State_Of (TTD) = Free,

        others => State_Of (TTD) = State_Of (TTD)'Old);

end Hybrid_Level_3;
