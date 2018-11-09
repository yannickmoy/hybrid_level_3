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
            for VSS in Track.TTD_View (TTD).First_VSS ..
                       Track.TTD_View (TTD).Last_VSS
            loop
               pragma Assert (TD_Before.VSS_View (VSS).State =
                              Track.VSS_View (VSS).State);
               pragma Loop_Invariant
                 (for all V in Track.TTD_View (TTD).First_VSS .. VSS =>
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

   procedure State_Transition (E : Event; TTD : TTD_Index) is
      Track_On_Entry : constant Track_Data := Track with Ghost;
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

                     Prove_Valid_Track_Data
                       (TD_Before   => Track_On_Entry,
                        Special_TTD => TTD);

                     pragma Assert (Valid_Track_Data (Track));

                  when Occupied =>
                     Set_State_Of (Track.TTD_View(TTD).First_VSS, Occupied);

                     Prove_Valid_Track_Data
                       (TD_Before   => Track_On_Entry,
                        Special_TTD => TTD);

                     pragma Assert (Valid_Track_Data (Track));
               end case;
            end if;
      end case;
   end State_Transition;

end Hybrid_Level_3;
