package body Hybrid_Level_3
  with SPARK_Mode
is
   --  Setters

   procedure Set_State_Of (TTD : TTD_Index; State : TTD_State) is
   begin
      Track.TTD_View(TTD).State := State;
   end Set_State_Of;

   procedure State_Transition (E : Event; TTD : TTD_Index) is
   begin
      case E.Kind is
         when TTD_State_Event =>
            if E.TTD = TTD then
               Set_State_Of (TTD, E.State);
            end if;
      end case;
   end State_Transition;

end Hybrid_Level_3;
