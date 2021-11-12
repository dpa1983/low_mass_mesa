# low\_mass\_mesa

To run ``MESA`` revision 7624 code on ``astrohub/wendi2``, go to a mesa work directory, e.g. to ``/user/scratch14_outreach/your_name/low_mass_mesa/`` ``work_low_mass_mesa_7624``, and execute the following commands:

* ``export MESA_DIR=/user/mesa/mesa_7624``
* ``export OMP_NUM_THREADS=4``

**Note** that these commands must be executed in **every** ``MESA`` work directory where you are going to run stellar evolution simulations.

Check that the directory ``data`` on the path ``$MESA_DIR`` has a ``kap_data`` directory of a size of 1.1 Gb. This must be a custom-made directory that includes opacities for alpha-enhanced Asplund+2009 solar composition. If the ``kap_data`` directory is of a size of 469 Mb ask Pavel Denisenkov to replace it with the right directory.

After that, try to first execute the command ``./mk`` to see that everything is set up correctly, otherwise there will be some error messages. **Make sure** that the mesa work directory has the sub-directories ``LOGS`` and ``photos``, and if it does not, make them. For ``MESA`` custom stellar evolution simulations, run the code with the command ``nice -n 19 ./rn``.