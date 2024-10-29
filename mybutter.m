function csc_filt=mybutter(csc,srate,lof,hif)
% Customized filter based on butter 

nyqf = srate/2; 
lof = lof/nyqf; hif = hif/nyqf;
[b,a] = butter(2, [lof hif]); 
csc_filt = filtfilt(b,a,csc);