! ***********************************************************************
!
!   Copyright (C) 2010  Bill Paxton
!
!   this file is part of mesa.
!
!   mesa is free software; you can redistribute it and/or modify
!   it under the terms of the gnu general library public license as published
!   by the free software foundation; either version 2 of the license, or
!   (at your option) any later version.
!
!   mesa is distributed in the hope that it will be useful, 
!   but without any warranty; without even the implied warranty of
!   merchantability or fitness for a particular purpose.  see the
!   gnu library general public license for more details.
!
!   you should have received a copy of the gnu library general public license
!   along with this software; if not, write to the free software
!   foundation, inc., 59 temple place, suite 330, boston, ma 02111-1307 usa
!
! ***********************************************************************
 
      module run_star_extras

      use star_lib
      use star_def
      use const_def
      
      implicit none
      
      ! these routines are called by the standard run_star check_model
      contains
      
!     include 'standard_run_star_extras.inc'
      
      subroutine extras_controls(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         
         ! this is the place to set any procedure pointers you want to change
         ! e.g., other_wind, other_mixing, other_energy  (see star_data.inc)

         s % other_D_mix => pavel_mixing_HB          
         
      end subroutine extras_controls
      
      
      integer function extras_startup(id, restart, ierr)
         integer, intent(in) :: id
         logical, intent(in) :: restart
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_startup = 0
         if (.not. restart) then
            call alloc_extra_info(s)
         else ! it is a restart
            call unpack_extra_info(s)
         end if
      end function extras_startup
      

      ! returns either keep_going, retry, backup, or terminate.
      integer function extras_check_model(id, id_extra)
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_check_model = keep_going         
         if (.false. .and. s% star_mass_h1 < 0.35d0) then
            ! stop when star hydrogen mass drops to specified level
            extras_check_model = terminate
            write(*, *) 'have reached desired hydrogen mass'
            return
         end if

! *** dpa *** mass loss is turned on only on the RGB
       ! if( s% log_surface_luminosity > 1.0 &
       !    .and. s% center_h1 < 1d-6) s% Reimers_wind_eta = 0.4
         if( s% log_surface_luminosity > 2.5 &
          .and. s% center_h1 < 1d-6) s% do_element_diffusion = .false.
! *** dpa ***

         ! if you want to check multiple conditions, it can be useful
         ! to set a different termination code depending on which
         ! condition was triggered.  MESA provides 9 customizeable
         ! termination codes, named t_xtra1 .. t_xtra9.  You can
         ! customize the messages that will be printed upon exit by
         ! setting the corresponding termination_code_str value.
         ! termination_code_str(t_xtra1) = 'my termination condition'

         ! by default, indicate where (in the code) MESA terminated
         if (extras_check_model == terminate) s% termination_code = t_extras_check_model
      end function extras_check_model


      integer function how_many_extra_history_columns(id, id_extra)
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_history_columns = 0
      end function how_many_extra_history_columns
      
      subroutine data_for_extra_history_columns(id, id_extra, n, names, vals, ierr)
         integer, intent(in) :: id, id_extra, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         !note: do NOT add the extras names to history_columns.list
         ! the history_columns.list is only for the built-in log column options.
         ! it must not include the new column names you are adding here.


      end subroutine data_for_extra_history_columns      
      
      integer function how_many_extra_profile_columns(id, id_extra)
         use star_def, only: star_info
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_profile_columns = 0
      end function how_many_extra_profile_columns
      
      
      subroutine data_for_extra_profile_columns(id, id_extra, n, nz, names, vals, ierr)
         use star_def, only: star_info, maxlen_profile_column_name
         use const_def, only: dp
         integer, intent(in) :: id, id_extra, n, nz
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(nz,n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         integer :: k
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         
         !note: do NOT add the extra names to profile_columns.list
         ! the profile_columns.list is only for the built-in profile column options.
         ! it must not include the new column names you are adding here.

         ! here is an example for adding a profile column
         !if (n /= 1) stop 'data_for_extra_profile_columns'
         !names(1) = 'beta'
         !do k = 1, nz
         !   vals(k,1) = s% Pgas(k)/s% P(k)
         !end do
         
      end subroutine data_for_extra_profile_columns
      

      ! returns either keep_going or terminate.
      ! note: cannot request retry or backup; extras_check_model can do that.
      integer function extras_finish_step(id, id_extra)
         integer, intent(in) :: id, id_extra
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_finish_step = keep_going
         call store_extra_info(s)

         ! to save a profile, 
            ! s% need_to_save_profiles_now = .true.
         ! to update the star log,
            ! s% need_to_update_history_now = .true.

         ! see extras_check_model for information about custom termination codes
         ! by default, indicate where (in the code) MESA terminated
         if (extras_finish_step == terminate) s% termination_code = t_extras_finish_step
      end function extras_finish_step
      
      
      subroutine extras_after_evolve(id, id_extra, ierr)
         integer, intent(in) :: id, id_extra
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
      end subroutine extras_after_evolve
      
      
      ! routines for saving and restoring extra data so can do restarts
         
         ! put these defs at the top and delete from the following routines
         !integer, parameter :: extra_info_alloc = 1
         !integer, parameter :: extra_info_get = 2
         !integer, parameter :: extra_info_put = 3
      
      
      subroutine alloc_extra_info(s)
         integer, parameter :: extra_info_alloc = 1
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_alloc)
      end subroutine alloc_extra_info
      
      
      subroutine unpack_extra_info(s)
         integer, parameter :: extra_info_get = 2
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_get)
      end subroutine unpack_extra_info
      
      
      subroutine store_extra_info(s)
         integer, parameter :: extra_info_put = 3
         type (star_info), pointer :: s
         call move_extra_info(s,extra_info_put)
      end subroutine store_extra_info
      
      
      subroutine move_extra_info(s,op)
         integer, parameter :: extra_info_alloc = 1
         integer, parameter :: extra_info_get = 2
         integer, parameter :: extra_info_put = 3
         type (star_info), pointer :: s
         integer, intent(in) :: op
         
         integer :: i, j, num_ints, num_dbls, ierr
         
         i = 0
         ! call move_int or move_flg    
         num_ints = i
         
         i = 0
         ! call move_dbl       
         
         num_dbls = i
         
         if (op /= extra_info_alloc) return
         if (num_ints == 0 .and. num_dbls == 0) return
         
         ierr = 0
         call star_alloc_extras(s% id, num_ints, num_dbls, ierr)
         if (ierr /= 0) then
            write(*,*) 'failed in star_alloc_extras'
            write(*,*) 'alloc_extras num_ints', num_ints
            write(*,*) 'alloc_extras num_dbls', num_dbls
            stop 1
         end if
         
         contains
         
         subroutine move_dbl(dbl)
            real(dp) :: dbl
            i = i+1
            select case (op)
            case (extra_info_get)
               dbl = s% extra_work(i)
            case (extra_info_put)
               s% extra_work(i) = dbl
            end select
         end subroutine move_dbl
         
         subroutine move_int(int)
            integer :: int
            i = i+1
            select case (op)
            case (extra_info_get)
               int = s% extra_iwork(i)
            case (extra_info_put)
               s% extra_iwork(i) = int
            end select
         end subroutine move_int
         
         subroutine move_flg(flg)
            logical :: flg
            i = i+1
            select case (op)
            case (extra_info_get)
               flg = (s% extra_iwork(i) /= 0)
            case (extra_info_put)
               if (flg) then
                  s% extra_iwork(i) = 1
               else
                  s% extra_iwork(i) = 0
               end if
            end select
         end subroutine move_flg
      
      end subroutine move_extra_info

      subroutine pavel_mixing_HB(id, ierr)

         use chem_def, only: ih1, ihe4

       !
       ! with the most recent versions of MESA use this
       !
         use mlt_def
         use star_lib, only: star_ptr, star_adjust_gradT_fraction, &
                             star_adjust_gradT_excess

         integer, intent(in) :: id
         integer, intent(out) :: ierr
         integer :: k, nz, h1, he4, k_t, k_c
         double precision :: dq00, dqm1, dqsum, T, kap, rho, cp, &
           thermal_diffusivity, gradr, grada, alpha, fac0, fac
         type (star_info), pointer :: s
         ierr = 0
         call get_star_ptr(id, s, ierr)
         if (ierr /= 0) return

         h1 = s% net_iso(ih1)
         he4 = s% net_iso(ihe4)

         nz = s% nz

       ! find top of He core shell (k_t)
         k_t = 0
         do k = 2, nz
            if (s% xa(h1,k) > 1d-6) cycle
               k_t = k; exit
         end do

       ! find top of He convective core shell (k_c)
         k_c = k_t
         do k = k_t, nz 
            gradr = s% gradr(k)
            grada = s% grada_at_face(k)
            if (gradr.lt.grada) cycle
               k_c = k; exit
         end do

         fac = s% x_ctrl(2)*(gradr/grada) + s% x_ctrl(3)
         fac0 = s% x_ctrl(4)

       ! turn off cbm if central He mass fraction is small
         if (s% xa(he4,nz).lt.s% x_ctrl(5)) &
            fac = fac*(s% xa(he4,nz)/s% x_ctrl(5))

            ! For helium burning regions.

         s% overshoot_f_above_burn_he_core = fac
         s% overshoot_f0_above_burn_he_core = fac0
         s% overshoot_f_above_burn_he_shell = fac    
         s% overshoot_f0_above_burn_he_shell = fac0 
         s% overshoot_f_below_burn_he_shell = fac    
         s% overshoot_f0_below_burn_he_shell = fac0 

            ! For metals burning regions.

         s% overshoot_f_above_burn_z_core = fac   
         s% overshoot_f0_above_burn_z_core = fac0 
         s% overshoot_f_above_burn_z_shell = fac   
         s% overshoot_f0_above_burn_z_shell = fac0 
         s% overshoot_f_below_burn_z_shell = fac   
         s% overshoot_f0_below_burn_z_shell = fac0 

            ! For nonburning regions.

         s% overshoot_f_above_nonburn_core = fac     
         s% overshoot_f0_above_nonburn_core = fac0  
         s% overshoot_f_above_nonburn_shell = fac   
         s% overshoot_f0_above_nonburn_shell = fac0  
         s% overshoot_f_below_nonburn_shell = fac   
         s% overshoot_f0_below_nonburn_shell = fac0  

         do k = k_c, nz 
           ! interpolate values at face

            dq00 = s% dq(k)
            dqm1 = s% dq(k-1)
            dqsum = dq00 + dqm1
            kap = (dqm1*s% opacity(k) + dq00*s% opacity(k-1))/dqsum
            rho = (dqm1*s% rho(k) + dq00*s% rho(k-1))/dqsum
            cp = (dqm1*s% cp(k) + dq00*s% cp(k-1))/dqsum
            T = (dqm1*s% T(k) + dq00*s% T(k-1))/dqsum
            thermal_diffusivity = 4*crad*clight*T**3/(3*kap*rho**2*cp)

            gradr = s% gradr(k)
            grada = s% grada_at_face(k)

            if (s% D_mix(k).lt.thermal_diffusivity) then
               s% D_mix(k) = s% x_ctrl(6) * thermal_diffusivity
               s% mixing_type(k) = thermohaline_mixing     
            end if

         end do

      end subroutine pavel_mixing_HB

      end module run_star_extras
