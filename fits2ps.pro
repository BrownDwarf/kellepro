PRO fits2ps, fitsinput,ir=ir,fnu=fnu,xr=xr,yr=yr

;converts fits to postscrip plot FOR printing.

;CALLS
;from IDL lib readfits, 
;from kellepro: norm_spec, kreadspec

IF N_params() lt 1 THEN BEGIN
     print,'Syntax -  FITS2PS, fitsfilename [,/IR,/FNU]'
     return
ENDIF

rootname=(strsplit(FitsInput,'.',/extract))[0]
ext=(strsplit(FitsInput,'.',/extract))[1]

angstrom=STRING(197B)

IF keyword_set(ir) THEN BEGIN
   spec=READFITS(fitsinput,h)
   w=spec[0,*]
   flux=spec[1,*]
   xunit='(!9m!3m)'
   xpos=0.7
   IF keyword_set(fnu) THEN BEGIN
      yunit='Flux (Jy)'
   ENDIF ELSE BEGIN
      flux=flux * 3e-13 / w^2
      yunit='Flux (ergs/s/cm!E2!N/'+angstrom+')'
   ENDELSE
   
ENDIF ELSE BEGIN
   object_data = KREADSPEC(fitsinput, h, /NORM)
   flux = object_data[1,*]
   w = object_data[0,*]
   xunit=angstrom
   yunit='Normalized Flux (ergs/s/cm!E2!N/'+angstrom+')'
   xpos=0.15
ENDELSE

object_name = strtrim(sxpar(h,'OBJECT'),2)
telescope = sxpar(h,'TELESCOP')
date_obs = sxpar(h,'DATE_OBS',count=count)
IF count EQ 0 THEN date_obs = sxpar(h,'DATE',count=count)
IF count EQ 0 THEN date_obs=sxpar(h,'DATE-OBS',count=count)
angstrom=STRING(197B)
!p.font=0
set_plot, 'ps'
device, filename=rootname+'.ps', encapsulated=0, /helvetica, /isolatin1,/landscape, $
        xsize=10.5, ysize=8.0, /inches, xoffset=0.3, yoffset=10.7

IF keyword_set(xr) THEN xs=1 ELSE BEGIN
   xr=[min(w),max(w)]
   xs=0
ENDELSE
IF keyword_set(yr) THEN ys=1 ELSE BEGIN 
   yr=[min(flux),max(flux)]
   ys=0
ENDELSE

plot, w,flux,xr=xr,xstyle=xs,yr=yr,ystyle=ys,$
      xtitle='Wavelength '+'('+xunit+')', ytitle=yunit

feat

xyouts, xpos,0.5, object_name,charsize=1.5,/NORMAL

XYOUTS, 0.75,0.92, telescope,/NORMAL
XYOUTS, 0.75,0.89, date_obs, /NORMAL

device, /close
set_plot,'x'

MESSAGE, 'Wrote: '+object_name+'.ps',/info

;stop

END
