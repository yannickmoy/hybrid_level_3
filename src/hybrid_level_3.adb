package body Hybrid_Level_3
  with SPARK_Mode
is
   --  Setters

   procedure Set_State_Of (VSS : VSS_Index; State : VSS_State) is
   begin
      Track.VSS_View(VSS).State := State;
   end Set_State_Of;

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

               case E.State is
                  when Free =>
                     for VSS in Track.TTD_View(TTD).First_VSS ..
                                Track.TTD_View(TTD).Last_VSS
                     loop
                        Set_State_Of (VSS, Free);
                        pragma Loop_Invariant
                          (for all V in VSS_Index =>
                             (if V in Track.TTD_View(TTD).First_VSS .. VSS then
                                Track.VSS_View(V) =
                                Track.VSS_View'Loop_Entry(V)'Update(State => Free)
                              else
                                Track.VSS_View(V) = Track.VSS_View'Loop_Entry(V)));
                     end loop;
                  when Occupied =>
                     Set_State_Of (Track.TTD_View(TTD).First_VSS, Occupied);
               end case;
            end if;
      end case;
   end State_Transition;

end Hybrid_Level_3;
