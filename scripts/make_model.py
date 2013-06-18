#! /usr/bin/env python
from make2FGLxml import *
# ----------------------------------------------------------------
# ----------- BEGIN SETTINGS -------------------------------------
# ----------------------------------------------------------------
# IDENTICAL TO SETTINGS IN GTRUN.SH!!
obj='3c120'
anadir='/home/mjaniak/fermi/3c120/analysis'
anaid='global_r30'
# energy=[ 100.00, 199.53, 398.11, 794.33, 1584.89, 3162.28, 6309.57, 12589.25, 25118.86, 50118.72, 100000.00 ]
energy=[ 100.00, 100000.00 ]
# ----------------------------------------------------------
catalogue='/home/mjaniak/fermi/catalog_dir/gll_psc_v08.fit'
gal_model_file='/home/mjaniak/fermi/diffuse_dir/gal_2yearp7v6_v0.fits'
gal_model_name='gal_2yearp7v6_v0'
iso_model_file='/home/mjaniak/fermi/diffuse_dir/iso_p7v6source.txt'
iso_model_name='iso_p7v6source'
# ----------------------------------------------------------------
# ----------- END SETTINGS ---------------------------------------
# ----------------------------------------------------------------

DIR=anadir+'/'+anaid+'/Energy'+str( '%1.2f' % energy[0])
fits=anadir+'/'+anaid+'/Energy'+str( '%1.2f' % energy[0])+'/'+obj+'_filtered.fits'
print 'Using evnt file',fits
mymodel=srcList(catalogue,fits,anadir+'/'+anaid+'/'+obj+'_binned_model.xml')
mymodel.makeModel(gal_model_file,gal_model_name,iso_model_file,iso_model_name)
