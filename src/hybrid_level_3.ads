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

   type VSS_Static_Data is record
      Inside_TTD : TTD_Index;
   end record;

   type VSS_Static_On_Track is array (VSS_Index) of VSS_Static_Data;

   type VSS_Data is record
      State : VSS_State;
   end record;

   type VSS_On_Track is array (VSS_Index) of VSS_Data;

   --  Types defining TTD data

   subtype TTD_State is VSS_State range Free .. Occupied;

   type TTD_Static_Data is record
      First_VSS : VSS_Index;
      Last_VSS  : VSS_Index;
   end record
     with Dynamic_Predicate => First_VSS <= Last_VSS;

   type TTD_Static_On_Track is array (TTD_Index) of TTD_Static_Data;

   type TTD_Data is record
      State                     : TTD_State;
      Last_Train_Located_On_TTD : Train_ID;
   end record;

   type TTD_On_Track is array (TTD_Index) of TTD_Data;

   type Track_Static_Data is record
      VSS_View : VSS_Static_On_Track;
      TTD_View : TTD_Static_On_Track;
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
                          TTD_View(VSS_View(VSS).Inside_TTD).Last_VSS)
       and then (for all TTD in TTD_Index =>
                   (for all VSS in TTD_View(TTD).First_VSS ..
                                   TTD_View(TTD).Last_VSS =>
                        VSS_View(VSS).Inside_TTD = TTD));

   type Track_Data is record
      VSS_View : VSS_On_Track;
      TTD_View : TTD_On_Track;
   end record;

   --  Types defining the trains

   type Length is range 1 .. 10_000;

   type Train_Data is record
      Train_Length   : Length;
      Front_Position : TTD_Index;
   end record;

   type Trains_Data is array (Train_ID) of Train_Data;

   --  Global variables defining the state

   Track_Static : Track_Static_Data;
   Track        : Track_Data;
   Trains       : Trains_Data;

   --  A TDD is Free iff all the corresponding VSS are Free

   function Valid_Track_Data (TD : Track_Data; TTD : TTD_Index) return Boolean
   is
     ((TD.TTD_View (TTD).State = Free) =
      (for all VSS in Track_Static.TTD_View (TTD).First_VSS ..
                      Track_Static.TTD_View (TTD).Last_VSS =>
         TD.VSS_View (VSS).State = Free));

   function Valid_Track_Data (TD : Track_Data) return Boolean is
     (for all TTD in TTD_Index => Valid_Track_Data (TD, TTD));

   --  Getters

   function State_Of (VSS : VSS_Index) return VSS_State is
      (Track.VSS_View(VSS).State);

   function State_Of (TTD : TTD_Index) return TTD_State is
      (Track.TTD_View(TTD).State);

   function TTD_Of (VSS : VSS_Index) return TTD_Index is
      (Track_Static.VSS_View(VSS).Inside_TTD);

   function First_VSS_Of (TTD : TTD_Index) return VSS_Index is
      (Track_Static.TTD_View(TTD).First_VSS);

   function Last_VSS_Of (TTD : TTD_Index) return VSS_Index is
      (Track_Static.TTD_View(TTD).Last_VSS);

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

   procedure State_Transition (E : Event; VSS : VSS_Index) with
     Global => (In_Out => Track,
                Input  => Track_Static),
     Post =>
       --  The state of the track is at most modified in the state of the VSS
       --  passed in argument.
       (for Some New_State in VSS_State =>
          Track = Track'Old'Update
            (VSS_View => Track.VSS_View'Old'Update (VSS => (State => New_State)))),

     Contract_Cases =>
       (E.Kind = TTD_State_Event
        and then E.TTD = TTD_Of (VSS)
        and then E.State = Occupied
        and then VSS = First_VSS_Of (TTD_Of (VSS))
        => State_Of (VSS) = Occupied,

        E.Kind = TTD_State_Event
        and then E.TTD = TTD_Of (VSS)
        and then E.State = Free
        => State_Of (VSS) = Free,

        others => State_Of (VSS) = State_Of (VSS)'Old);

   procedure Handle_Event (E : Event) with
     Pre  => Valid_Track_Data (Track),
     Post => Valid_Track_Data (Track);

end Hybrid_Level_3;
