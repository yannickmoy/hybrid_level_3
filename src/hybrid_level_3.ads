package Hybrid_Level_3
  with SPARK_Mode
is

   type Train_ID is range 1 .. 50;

   --  Types defining TTD data

   type TTD_Index is range 1 .. 100;

   type TTD_State is (Free, Occupied);

   type TTD_Data is record
      State                     : TTD_State;
      Last_Train_Located_On_TTD : Train_ID;
   end record;

   type TTD_On_Track is array (TTD_Index) of TTD_Data;

   type Track_Data is record
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

   Track  : Track_Data;
   Trains : Trains_Data;

   --  Getters

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

   procedure State_Transition (E : Event; TTD : TTD_Index)
     with Contract_Cases =>
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
