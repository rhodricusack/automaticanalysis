% This function is automagically generated by aa_build_standalone_1_pragmas
function varargout=aa_feval(funcname,varargin)
%#function aamod_ANTS_EPIwarp aamod_ANTS_build_MMtemplate aamod_ANTS_build_template aamod_ANTS_struc2epi aamod_ANTS_struc2template aamod_ANTS_warp aamod_GLMdenoise aamod_LoAd aamod_LoAd2SPM aamod_LouvainCluster aamod_MP2RAGE aamod_MTI2MTR aamod_autoidentifyseries aamod_autoidentifyseries_siemens aamod_bet aamod_bet_epi_masking aamod_bet_epi_reslicing aamod_bet_freesurfer aamod_bet_premask aamod_biascorrect aamod_biascorrect_ANTS aamod_biascorrect_segment8 aamod_biascorrect_segment8_multichan aamod_binarizeimage aamod_binaryfromlabels aamod_brainmask aamod_brainmaskcombine aamod_checkparameters aamod_clusteringXValidation aamod_compSignal aamod_compareoverlap aamod_convert_diffusion aamod_convert_dmdx aamod_convert_epis aamod_convert_fieldmaps aamod_convert_specialseries aamod_convert_structural aamod_copy_image_orientation aamod_coreg_extended aamod_coreg_extended_1 aamod_coreg_extended_2 aamod_coreg_general aamod_coreg_noss aamod_coreg_structural2fa aamod_coreg_structural2template aamod_coregisterstructural2template aamod_dartel_createtemplate aamod_dartel_denorm aamod_dartel_normmni aamod_decodeDMLT aamod_denoiseANLM aamod_diffusion_bedpostx aamod_diffusion_dki_tractography_prepare aamod_diffusion_dkifit aamod_diffusion_dtifit aamod_diffusion_dtinlfit aamod_diffusion_eddy aamod_diffusion_eddycorrect aamod_diffusion_extractnodif aamod_diffusion_probtrackx aamod_diffusion_probtrackxsummarize_group aamod_diffusion_probtrackxsummarize_indv aamod_diffusion_roi_valid aamod_diffusion_topup aamod_diffusionfromnifti aamod_epifromnifti aamod_evaluatesubjectnames aamod_fconn_computematrix aamod_fconnmatrix_seedseed aamod_fieldmap2VDM aamod_fieldmapfromnifti aamod_firstlevel_contrasts aamod_firstlevel_model aamod_firstlevel_model_MVPaa aamod_firstlevel_modelspecify aamod_firstlevel_threshold aamod_freesurfer_autorecon aamod_freesurfer_deface aamod_freesurfer_deface_apply aamod_freesurfer_initialise aamod_freesurfer_register aamod_fsl_FAST aamod_fsl_FIRST aamod_fsl_reorienttoMNI aamod_fsl_robustFOV aamod_fslmaths aamod_fslmerge aamod_fslsplit aamod_garbagecollection aamod_get_dicom_ASL aamod_get_dicom_diffusion aamod_get_dicom_epi aamod_get_dicom_fieldmap aamod_get_dicom_specialseries aamod_get_dicom_structural aamod_get_tSNR aamod_ggmfit aamod_highpass aamod_highpassfilter_epi aamod_imcalc aamod_importfilesasstream aamod_input_staging aamod_listspikes aamod_make_epis_float aamod_mapstreams aamod_marsbar aamod_mask_fromsegment aamod_mask_fromstruct aamod_maths aamod_meanepitimecourse aamod_meg_average aamod_meg_convert aamod_meg_denoise_ICA_1 aamod_meg_denoise_ICA_2_applytrajectory aamod_meg_epochs aamod_meg_get_fif aamod_meg_grandmean aamod_meg_maxfilt aamod_meg_merge aamod_melodic aamod_mirrorandsubtract aamod_modelestimate aamod_movie aamod_moviecorr_meantimecourse aamod_moviecorr_summary aamod_newsubj_init aamod_norm_noss aamod_norm_vbm aamod_norm_write aamod_norm_write_dartel aamod_normalisebytotalgrey aamod_oneway_ANOVA aamod_pewarp_estimate aamod_pewarp_write aamod_possum aamod_ppi_model aamod_ppi_prepare aamod_realign aamod_realignunwarp aamod_reorientto aamod_reorienttomiddle aamod_reslice aamod_resliceROI aamod_reslice_rois aamod_roi_extract aamod_roi_valid aamod_rois_getvalues aamod_secondlevel_GIFT aamod_secondlevel_contrasts aamod_secondlevel_model aamod_secondlevel_randomise aamod_secondlevel_threshold aamod_seedConnectivity aamod_segment aamod_segment8 aamod_segmentvbm8 aamod_slicetiming aamod_smooth aamod_smooth_structurals aamod_split aamod_structural_overlay aamod_structuralfromnifti aamod_structuralstats aamod_study_init aamod_tSNR_EPI aamod_temporalfilter aamod_tensor_ica aamod_tissue_spectrum aamod_tissue_spectrum_summarize aamod_tissue_wavelets aamod_tissue_wavelets_summarize aamod_trimEPIVols aamod_tsdiffana aamod_unnormalise_rois aamod_unnormalise_rois2 aamod_unzipstream aamod_vois_extract aamod_waveletdespike aamod_MVPaa_brain_1st aamod_MVPaa_brain_SPM aamod_MVPaa_roi_1st aamod_MVPaa_roi_2nd aamod_template_session
    try
        nout = max(nargout(funcname),1);
    catch myerr
        if (strcmp(myerr.identifier,'MATLAB:narginout:notValidMfile'))
           aas_log([],false,sprintf('%s doesn''t appear to be a valid m file?',funcname));
        else
            throw(myerr);
        end;
    end;

    varargout = cell(1,nout);
    [varargout{:}]=feval(funcname,varargin{:});
end
