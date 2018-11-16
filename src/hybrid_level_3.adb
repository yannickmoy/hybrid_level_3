package body Hybrid_Level_3
  with SPARK_Mode
is
   --  Inlined ghost code

   --  Prove that except for the [Special_TTD], the current [Track] is valid
   --  for all other values of TTD, based on the fact it was previously the
   --  case with track data [TD_Before], and the track data has not changed
   --  for TDD. This procedure is ghost without contract so that its body is
   --  inlined for proof.
   procedure Prove_Valid_Track_Data
     (TD_Before   : Track_Data;
      Special_TTD : TTD_Index)
   with Ghost
   is
   begin
      for TTD in TTD_Index loop
         if TTD /= Special_TTD then
            pragma Assert (Valid_Track_Data (TD_Before, TTD));
            pragma Assert (TD_Before.TTD_View (TTD) =
                           Track.TTD_View (TTD));
            for VSS in Track_Static.TTD_View (TTD).First_VSS ..
                       Track_Static.TTD_View (TTD).Last_VSS
            loop
               pragma Assert (TD_Before.VSS_View (VSS).State =
                              Track.VSS_View (VSS).State);
               pragma Loop_Invariant
                 (for all V in Track_Static.TTD_View (TTD).First_VSS .. VSS =>
                    TD_Before.VSS_View (V).State =
                    Track.VSS_View (V).State);
            end loop;
            pragma Assert (Valid_Track_Data (Track, TTD));
         end if;

         pragma Loop_Invariant
           (for all T in TTD_Index'First .. TTD =>
              (if T /= Special_TTD then Valid_Track_Data (Track, T)));
      end loop;
   end Prove_Valid_Track_Data;

   --  Setters

   procedure Set_State_Of (VSS : VSS_Index; State : VSS_State) is
   begin
      Track.VSS_View(VSS).State := State;
   end Set_State_Of;

   procedure Set_State_Of (TTD : TTD_Index; State : TTD_State) is
   begin
      Track.TTD_View(TTD).State := State;
   end Set_State_Of;

   procedure State_Transition (E : Event; VSS : VSS_Index) is
      TTD : constant TTD_Index := TTD_Of (VSS);
   begin
      case E.Kind is
         when TTD_State_Event =>
            if E.TTD = TTD then
               case E.State is
                  when Free =>
                     Set_State_Of (VSS, Free);
                  when Occupied =>
                     if VSS = Track_Static.TTD_View(TTD).First_VSS then
                        Set_State_Of (VSS, Occupied);
                     end if;
               end case;
            end if;
      end case;
   end State_Transition;

   procedure Handle_Event (E : Event) is
      Track_On_Entry : constant Track_Data := Track with Ghost;
   begin
      case E.Kind is
         when TTD_State_Event =>
            declare
               TTD : constant TTD_Index := E.TTD;
            begin
               Set_State_Of (TTD, E.State);

               case E.State is
                  when Free =>
                     for VSS in Track_Static.TTD_View(TTD).First_VSS ..
                                Track_Static.TTD_View(TTD).Last_VSS
                     loop
                        State_Transition (E, VSS);
                        pragma Loop_Invariant
                          (Track = Track'Loop_Entry'Update
                             (VSS_View => Track.VSS_View'Loop_Entry'Update
                                (Track_Static.TTD_View(TTD).First_VSS .. VSS =>
                                   (State => Free))));
                     end loop;

                     Prove_Valid_Track_Data
                       (TD_Before   => Track_On_Entry,
                        Special_TTD => TTD);

                     pragma Assert (Valid_Track_Data (Track));

                  when Occupied =>
                     State_Transition (E, Track_Static.TTD_View(TTD).First_VSS);

                     Prove_Valid_Track_Data
                       (TD_Before   => Track_On_Entry,
                        Special_TTD => TTD);

                     pragma Assert (Valid_Track_Data (Track));
               end case;
            end;
      end case;
   end Handle_Event;

end Hybrid_Level_3;
