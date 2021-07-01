% AA module - first level thresholding
% **********************************************************************
% You should no longer need to change this module - you may just
% modify the .xml or model in your user script
% **********************************************************************
% Tibor Auer MRC CBU Cambridge 2012-2013
%
% CHANGE HISTORY
%
% 07/2018 --  added explicit template parameter to xml. Save SPM
% stats table. Added zero-sig-voxel watermark. Save all maps and 
% renders (even zero sig voxel results). 
% Add sanity check(s). Added optional "description" text which is
% overlayed on map if defined. General cleanup. [MSJ]

function [aap,resp]=aamod_firstlevel_threshold(aap,task,subj)

resp='';

switch task
    
    case 'report'
        
        % collect contrast names and prepare summary
        contrasts = aas_getsetting(aas_setcurrenttask(aap,aap.internal.inputstreamsources{aap.tasklist.currenttask.modulenumber}.stream(1).sourcenumber),'contrasts');
        cons = [contrasts(2:end).con];
        conNames = {cons.name};
        [~,a] = unique(conNames,'first');
        conNames = conNames(sort(a));
        
        if subj == 1 % first
            for C = 1:numel(conNames)
                if  ~isfield(aap.report,sprintf('html_C%02d',C))
                    aap.report.(sprintf('html_C%02d',C)).fname = fullfile(aap.report.condir,[aap.report.fbase sprintf('_C%02d.htm',C)]);
                    aap = aas_report_add(aap,'C00',...
                        sprintf('<a href="%s" target=_top>%s</a><br>',...
                        aap.report.(sprintf('html_C%02d',C)).fname,...
                        ['Contrast: ' conNames{C}]));
                    aap = aas_report_add(aap,sprintf('C%02d',C),['HEAD=Contrast: ' conNames{C}]);
                end
                if ~isempty(aap.tasklist.currenttask.extraparameters.aap.directory_conventions.analysisid_suffix)
                    aap = aas_report_add(aap,sprintf('C%02d',C),sprintf('<h2>Branch: %s</h2>',...
                        aap.tasklist.currenttask.extraparameters.aap.directory_conventions.analysisid_suffix(2:end)));
                end
            end
        end
        
        fSPM = aas_getfiles_bystream(aap, subj,'firstlevel_spm');
        loaded = load(fSPM);
        
        for C = 1:numel(loaded.SPM.xCon)
            
            conName = strrep_multi(loaded.SPM.xCon(C).name,{' ' ':' '>'},{'' '_' '-'});
            conInd = find(strcmp(conNames,loaded.SPM.xCon(C).name));
            if isempty(conInd), continue, end
            
            aap = aas_report_add(aap,sprintf('C%02d',conInd),['Subject: ' basename(aas_getsubjpath(aap,subj)) '<br>']);
            
            aap = aas_report_add(aap,subj,sprintf('<h4>%02d. %s</h4>',conInd,conName));
            
            f{1} = fullfile(aas_getsubjpath(aap,subj),...
                sprintf('diagnostic_aamod_firstlevel_threshold_C%02d_%s_overlay_3_001.jpg',conInd,conName));
            
            % older versions didn't create overlay/renders if no voxels
            % survived thresholding, ergo the check here. We now create
            % all images, but this check doesn't hurt, and may be useful
            % if generating a report on an old extant analysis
            
            if exist(f{1},'file')
                
                tstat = dlmread(strrep(f{1},'_overlay_3_001.jpg','.txt'));
                
                f{2} = fullfile(aas_getsubjpath(aap,subj),...
                    sprintf('diagnostic_aamod_firstlevel_threshold_C%02d_%s_render.jpg',conInd,conName));
                
                % add overlay and render images to single subject report...
                
                aap = aas_report_add(aap, subj,'<table><tr>');
                aap = aas_report_add(aap, subj, sprintf('T = %2.2f - %2.2f</tr><tr>', tstat(1), tstat(2)));
                for i = 1:2
                    aap = aas_report_add(aap, subj,'<td>');
                    aap = aas_report_addimage(aap, subj, f{i});
                    aap = aas_report_add(aap, subj,'</td>');
                end
                
                % add SPM stats table
                
                statsfname = fullfile(aas_getsubjpath(aap,subj),sprintf('table_firstlevel_threshold_C%02d_%s.jpg', conInd, conName));
                
                if ~exist(statsfname,'file')
                    make_stats_table(loaded.SPM, statsfname, C, ...
                        aap.tasklist.currenttask.settings.threshold.p, ...
                        aap.tasklist.currenttask.settings.threshold.correction);
                end
                
                aap = aas_report_add(aap, subj,'<td>');
                aap = aas_report_addimage(aap, subj, statsfname);
                aap = aas_report_add(aap, subj,'</td>');
                
                aap = aas_report_add(aap,subj,'</tr></table>');
                
                % ...also add images & table to module report
                
                aap = aas_report_add(aap,sprintf('C%02d',conInd),'<table><tr>');
                aap = aas_report_add(aap,sprintf('C%02d',conInd),sprintf('T = %2.2f - %2.2f</tr><tr>', tstat(1), tstat(2)));
                for i = 1:2
                    aap = aas_report_add(aap, sprintf('C%02d',conInd),'<td>');
                    aap = aas_report_addimage(aap,sprintf('C%02d',conInd), f{i});
                    aap = aas_report_add(aap,sprintf('C%02d',conInd),'</td>');
                end
                aap = aas_report_add(aap, sprintf('C%02d',conInd),'<td>');
                aap = aas_report_addimage(aap, sprintf('C%02d',conInd), statsfname);
                aap = aas_report_add(aap,sprintf('C%02d',conInd),'</td>');
                aap = aas_report_add(aap,sprintf('C%02d',conInd),'</tr></table>');
                
            end
            
        end
        
    case 'doit'
        
        % sanity checks
        
        if (strcmp(aap.tasklist.currenttask.settings.overlay.template,'structural'))
            aas_log(aap, false, sprintf('WARNING (%s): You should verify template ''structural'' is in the same space as ''epi''.', mfilename));
        end
        
        % Init
        
        try doTFCE = aap.tasklist.currenttask.settings.threshold.doTFCE; catch, doTFCE = 0; end % TFCE?
        corr = aap.tasklist.currenttask.settings.threshold.correction;		% correction
        u0   = aap.tasklist.currenttask.settings.threshold.p;			% height threshold
        k   = aap.tasklist.currenttask.settings.threshold.extent;		% extent threshold {voxels}
        nSl = aap.tasklist.currenttask.settings.overlay.nth_slice;
        tra = aap.tasklist.currenttask.settings.overlay.transparency;
        Outputs.thr = '';
        Outputs.sl = '';
        Outputs.Rend = '';
        
        cwd=pwd;
        localroot = aas_getsubjpath(aap,subj);
        anadir = fullfile(localroot,aap.directory_conventions.stats_singlesubj);
        cd(anadir);
        
        % we now explicitly define which structural template (native, normed, or SPMT1)
        % to use for overlay mapping rather than leaving it up to provenance
        
        switch  aap.tasklist.currenttask.settings.overlay.template
            
            case 'structural'
                
                % we can guarantee normalised_structural and SPMT1, but "structural"
                % could be native or normalised depending on tasklist. That's why
                % the option is called "structural" not "native" (although native
                % is intended).	If the user picks this option, we assume they know
                % what they're doing...
                
                if aas_stream_has_contents(aap,subj,'structural')
                    tmpfile = aas_getfiles_bystream(aap, subj, 'structural');
                else
                    aas_log(aap, true, sprintf('%s: Cannot find structural. Exiting...', mfilename));
                end
                
            case 'SPMT1'
                
                % assume a reasonable default location, but assume the user put
                % the correct location in aap.dir_con.T1template if it's not empty
                
                tmpfile = 'toolbox/OldNorm/T1.nii';
                if ~isempty(aap.directory_conventions.T1template), tmpfile = aap.directory_conventions.T1template; end
                if (tmpfile(1) ~= '/'), tmpfile = fullfile(fileparts(which('spm')),tmpfile); end
                
                if ~exist(tmpfile,'file')
                    aas_log(aap, true, sprintf('%s: SPM T1 template not found. Exiting...', mfilename));
                end
                
            otherwise
                
                aas_log(aap, true, sprintf('%s: Unknown template option. Exiting...', mfilename));
                
        end
        
        % Now get contrasts...
        
        SPM=[];
        fSPM = aas_getfiles_bystream(aap, subj,'firstlevel_spm');
        load(fSPM);
        
        for c = 1:numel(SPM.xCon)
            no_sig_voxels = false; % need this for later
            conName = strrep_multi(SPM.xCon(c).name,{' ' ':' '>'},{'' '_' '-'});
            STAT = SPM.xCon(c).STAT;
            df = [SPM.xCon(c).eidf SPM.xX.erdf];
            XYZ  = SPM.xVol.XYZ;
            S    = SPM.xVol.S;   % Voxel
            R    = SPM.xVol.R;   % RESEL
            V = spm_vol(fullfile(anadir, SPM.xCon(c).Vspm.fname));
            Z = spm_get_data(SPM.xCon(c).Vspm,XYZ);
            dim = SPM.xCon(c).Vspm.dim;
            VspmSv   = cat(1,SPM.xCon(c).Vspm);
            n = 1; % No conjunction
            
            if doTFCE
                job.spmmat = {fSPM};
                job.mask = {fullfile(fileparts(fSPM),'mask.nii,1')};
                job.conspec = struct( ...
                    'titlestr','', ...
                    'contrasts',c, ...
                    'n_perm',5000, ...
                    'vFWHM',0 ...
                    );
                job.tbss = 0;
                job.openmp = 1;
                cg_tfce_estimate(job);
                iSPM = SPM;
                iSPM.title = '';
                iSPM.Ic = c;
                iSPM.stattype = 'TFCE';
                iSPM.thresDesc = corr;
                iSPM.u = u0;
                iSPM.k = k;
                [SPM, xSPM] = cg_get_tfce_results(iSPM);
                Z = xSPM.Z;
                XYZ = xSPM.XYZ;
                if isempty(Z)
                    aas_log(aap,false,sprintf('INFO: No voxels survive TFCE(%s)=%1.4f, k=%0.2g',corr, u0, k));
                    no_sig_voxels = true;
                end
            else
                % Height threshold filtering
                switch corr
                    case 'iTT'
                        % TODO
                        [Z, XYZ, th] = spm_uc_iTT(Z,XYZ,u0,1);
                    case 'FWE'
                        u = spm_uc(u0,df,STAT,R,n,S);
                    case 'FDR'
                        u = spm_uc_FDR(u0,df,STAT,n,VspmSv,0);
                    case 'none'
                        u = spm_u(u0^(1/n),df,STAT);
                end
                Q      = find(Z > u);
                Z      = Z(:,Q);
                XYZ    = XYZ(:,Q);
                if isempty(Q)
                    aas_log(aap,false,sprintf('INFO: No voxels survive height threshold u=%0.2g',u));
                    no_sig_voxels = true;
                end
                
                % Extent threshold filtering
                if ischar(k) % probability-based
                    k = strsplit(k,':'); k{2} = str2double(k{2});
                    iSPM = SPM;
                    iSPM.Ic = c;
                    iSPM.thresDesc = corr;
                    iSPM.u = u0;
                    iSPM.k = 0;
                    iSPM.Im = [];
                    [~,xSPM] = spm_getSPM(iSPM);
                    T = spm_list('Table',xSPM);
                    switch k{1}
                        case {'FWE' 'FDR'}
                            k{1} = ['p(' k{1} '-corr)'];
                        case {'none'}
                            k{1} = 'p(unc)';
                    end
                    pInd = strcmp(T.hdr(1,:),'cluster') & strcmp(T.hdr(2,:),k{1});
                    kInd = strcmp(T.hdr(2,:),'equivk');
                    k = min(cell2mat(T.dat(cellfun(@(p) ~isempty(p) && p<k{2}, T.dat(:,pInd)),kInd)));
                end
                
                A     = spm_clusters(XYZ);
                Q     = [];
                for i = 1:max(A)
                    j = find(A == i);
                    if length(j) >= k
                        Q = [Q j];
                    end
                end
                Z     = Z(:,Q);
                XYZ   = XYZ(:,Q);
                if isempty(Q)
                    aas_log(aap,false,sprintf('INFO: No voxels survive extent threshold k=%0.2g',k));
                    no_sig_voxels = true;
                end
            end
            
            % Reconstruct
            Yepi  = zeros(dim(1),dim(2),dim(3));
            indx = sub2ind(dim,XYZ(1,:)',XYZ(2,:)',XYZ(3,:)');
            Yepi(indx) = Z;
            V.fname = spm_file(V.fname,'basename',strrep(spm_file(V.fname,'basename'),'spm','thr'));
            V.descrip = sprintf('thr{%s_%1.4f;ext_%d}%s',corr,u0,k,V.descrip(strfind(V.descrip,'}')+1:end));
            spm_write_vol(V,Yepi);
            
            % Overlay
            % - edges of activation
            slims = ones(4,2);
            sAct = arrayfun(@(x) any(Yepi(x,:,:),'all'), 1:size(Yepi,1));
            if numel(find(sAct))<2, slims(1,:) = [1 size(Yepi,1)];
            else, slims(1,:) = [find(sAct,1,'first') find(sAct,1,'last')]; end
            sAct = arrayfun(@(y) any(Yepi(:,y,:),'all'), 1:size(Yepi,2));
            if numel(find(sAct))<2, slims(2,:) = [1 size(Yepi,2)];
            else, slims(2,:) = [find(sAct,1,'first') find(sAct,1,'last')]; end
            sAct = arrayfun(@(z) any(Yepi(:,:,z),'all'), 1:size(Yepi,3));
            if numel(find(sAct))<2, slims(3,:) = [1 size(Yepi,3)];
            else, slims(3,:) = [find(sAct,1,'first') find(sAct,1,'last')]; end
            % - convert to mm
            slims = sort(V.mat*slims,2);
            % - extend if too narrow (min. 50mm)
            slims = slims + (repmat([-25 25],4,1).*repmat(diff(slims,[],2)<50,1,2));

            % - draw
            axis = {'sagittal','coronal','axial'};
            for a = 1:3
                if ~no_sig_voxels, stat_fname = {V.fname}; else, stat_fname = {}; end
                [fig, v] = map_overlay(tmpfile,stat_fname,axis{a},slims(a,1):nSl:slims(a,2));
                fnsl{a} = fullfile(localroot, sprintf('diagnostic_aamod_firstlevel_threshold_C%02d_%s_overlay_%d.jpg',c,conName,a));
                
                if (~isempty(aap.tasklist.currenttask.settings.description))
                    annotation('textbox',[0 0.5 0.5 0.5],'String',aap.tasklist.currenttask.settings.description,'FitBoxToText','on','fontweight','bold','color','y','fontsize',18,'backgroundcolor','k');
                end
                
                if (no_sig_voxels)
                    annotation('textbox',[0 0.475 0.5 0.5],'String','No voxels survive threshold','FitBoxToText','on','fontweight','bold','color','y','fontsize',18,'backgroundcolor','k');
                end
                
                spm_print(fnsl{a},fig,'jpg')
            end
            
            dlmwrite(fullfile(localroot, sprintf('diagnostic_aamod_firstlevel_threshold_C%02d_%s.txt',c,conName)),[min(v(v~=0)), max(v)]);
            
            % Render
            
            % FYI: render should always work regardless of template type because it
            % maps input into MNI, if necessary
            
            if ~no_sig_voxels
                if numel(Z)  < 2 % render fails with only one active voxel
                    Z = horzcat(Z,Z);
                    XYZ = horzcat(XYZ,XYZ);
                end
                % render fails with single first slice
                for a = 1:3
                    if all(XYZ(a,:)==1)
                        Z = horzcat(Z,Z(end));
                        XYZ = horzcat(XYZ,XYZ(:,end)+circshift([1;0;0],a-1));
                    end
                end
            end
            
            dat.XYZ = XYZ;
            dat.t = Z';
            dat.mat = SPM.xVol.M;
            dat.dim = dim;
            rendfile  = aap.directory_conventions.Render;
            if ~exist(rendfile,'file') && (rendfile(1) ~= '/'), rendfile = fullfile(fileparts(which('spm')),rendfile); end
            fn3d = fullfile(localroot,sprintf('diagnostic_aamod_firstlevel_threshold_C%02d_%s_render.jpg',c,conName));
            global prevrend
            prevrend = struct('rendfile',rendfile, 'brt',0.5, 'col',eye(3));
            out = spm_render(dat,0.5,rendfile); spm_figure('Close','Graphics');
            img = vertcat(horzcat(out{1},out{3},out{5}),horzcat(out{2},out{4},out{6}));
            fig = figure;
            imshow(img,'Border','tight');
            
            if (~isempty(aap.tasklist.currenttask.settings.description))
                annotation('textbox',[0 0.5 0.5 0.5],'String',aap.tasklist.currenttask.settings.description,'FitBoxToText','on','fontweight','bold','color','y','fontsize',18,'backgroundcolor','k');
            end
            
            if (no_sig_voxels)
                annotation('textbox',[0 0.45 0.5 0.5],'String','No voxels survive threshold','FitBoxToText','on','fontweight','bold','color','y','fontsize',18,'backgroundcolor','k');
            end
            
            print(fig,'-noui',fn3d,'-djpeg','-r300');
            close(fig);
            
            % Outputs
            
            if exist(V.fname,'file'), Outputs.thr = strvcat(Outputs.thr, V.fname); end
            for f = 1:numel(fnsl)
                if exist(fnsl{f},'file'), Outputs.sl = strvcat(Outputs.sl, fnsl{f}); end
            end
            if exist(fn3d,'file'), Outputs.Rend = strvcat(Outputs.Rend, fn3d); end
            
        end
        
        cd (cwd);
        
        % Describe outputs
        
        aap=aas_desc_outputs(aap,subj,'firstlevel_thr',Outputs.thr);
        aap=aas_desc_outputs(aap,subj,'firstlevel_thrslice',Outputs.sl);
        aap=aas_desc_outputs(aap,subj,'firstlevel_thr3D',Outputs.Rend);
        
    case 'checkrequirements'
        
    otherwise
        aas_log(aap,1,sprintf('Unknown task %s',task));
end

end

function make_stats_table(varargin)
%
% display and optionally save to jpeg an SPM thresholded stats table
%
% Usage:
%
%  make_stats_table(SPM, [fname, Ic, u, thresDesc, k, Im]);
%
% INPUT
%
%	SPM			- SPM struct containing thresholded results
%
% optional
%
%	fname		- jpeg name or path (omit or pass in [] to skip save)
%	Ic			- contrast # to examine
%	u			- threshold
%	thresDesc	- thresholding ('none' or 'FWE')
%	k			- cluster extent
%	Im			- masking option (currently ignored)
%
% if an optional parameter is missing, the following defaults are used:
%
%	no save (fname = [])
%	contrast #1 (Ic = 1)
%	significance = 0.001 (u = 0.001)
%	uncorrected (thresDesc = 'none')
%	voxel extent (k) = 0
%	no mask (Im = [])
%		
% sanity check

if (nargin < 1)
	fprintf('Usage: make_stats_table(SPM, [fname, Ic, u, thresDesc, k, Im])\n');
	return;
end

SPM = varargin{1};

% sanity check -- make sure the passed SPM has results to display 

if (~isfield(SPM,'xCon') || isempty(SPM.xCon))
	fprintf('%s: SPM struct does not contain contrasts. Aborting...\n', mfilename);
	return;
end

% defaults

fname = [];
SPM.Ic = 1;
SPM.u = 0.001;
SPM.thresDesc = 'none';
% 	SPM.u = 0.05;
% 	SPM.thresDesc = 'FWE';
SPM.k = 0;
SPM.Im = [];


if (nargin > 1)
	fname = varargin{2};
end

if (nargin > 2)
	SPM.Ic = varargin{3};
end

if (nargin > 3)
	SPM.u = varargin{4};
end

if (nargin > 4)
	SPM.thresDesc = varargin{5};
end

if (nargin > 5)
	SPM.k = varargin{6};
end

% Im is a ruse: currently we can only handle "no mask"

% 	if (nargin > 6)
%  		SPM.Im = varargin{7};
% 	end


% spm_list_display_noUI can only handle 'none' and 'FWE'

if (~strcmp(SPM.thresDesc,'none') && ~strcmp(SPM.thresDesc,'FWE'))
	fprintf('%s: Can only handle ''none'' and ''FWE'' thresholding. Aborting...\n', mfilename);
	return;
end

% extract info and make table

[~,xSPM] = spm_getSPM(SPM);
TabDat = spm_list('Table',xSPM);
hreg = spm_figure('CreateSatWin');
spm_list_display_noUI(TabDat,hreg);

% save?

if (~isempty(fname))

	set(hreg,'Renderer','opengl'); % I think this is the default

	% workaround for font rescaling weirdness

	set(findall(hreg,'Type','text'),'FontUnits','normalized');

	% tweak paper size to account for landscape layout

	set(hreg,'PaperUnits','inches','PaperPosition',[0 0 5 4]);

	% force jpg suffix otherwise there can be weirdness
	% also, bump up resolution to 200 bc numbers

	[p,n,~] = fileparts(fname);
	fname = fullfile(p,[n '.jpg']);

	print(hreg, '-djpeg', '-r200', fname, '-noui');

	close(hreg);

end

end


function spm_list_display_noUI(TabDat,hReg)
%
% this is essentially spm_list('Display',...) w/ the parts that expect
% the SPM interactive windows to be up and the parts that don't
% play nice with save-to-jpeg gutted. See make_stats_table for
% usage
%

    %-Setup Graphics panel
    %----------------------------------------------------------------------
    Fgraph = spm_figure('FindWin','Satellite');
    if ~isempty(Fgraph)
        spm_figure('Focus',Fgraph);
        ht = 0.85; bot = 0.14;
    else
        Fgraph = spm_figure('GetWin','Graphics');
        ht = 0.4; bot = 0.1;
    end
    spm_results_ui('Clear',Fgraph)
    FS     = spm('FontSizes');           %-Scaled font sizes
    PF     = spm_platform('fonts');      %-Font names (for this platform)
    
    %-Table axes & Title
    %----------------------------------------------------------------------
    hAx   = axes('Parent',Fgraph,...
                 'Position',[0.025 bot 0.9 ht],...
                 'DefaultTextFontSize',FS(8),...
                 'DefaultTextInterpreter','Tex',...
                 'DefaultTextVerticalAlignment','Baseline',...
                 'Tag','SPMList',...
                 'Units','points',...
                 'Visible','off');

    AxPos = get(hAx,'Position'); set(hAx,'YLim',[0,AxPos(4)])
    dy    = FS(9);
    y     = floor(AxPos(4)) - dy;

% this is not playing well with jpeg save
%
%     text(0,y,['Statistics:  \it\fontsize{',num2str(FS(9)),'}',TabDat.tit],...
%               'FontSize',FS(11),'FontWeight','Bold');   y = y - dy/2;

	line([0 1],[y y],'LineWidth',3,'Color','r'),        y = y - 9*dy/8;
    
    %-Display table header
    %----------------------------------------------------------------------
    set(hAx,'DefaultTextFontName',PF.helvetica,'DefaultTextFontSize',FS(8))

    Hs = []; Hc = []; Hp = [];
    h  = text(0.01,y, [TabDat.hdr{1,1} '-level'],'FontSize',FS(9)); Hs = [Hs,h];
    h  = line([0,0.11],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r'); Hs = [Hs,h];
    h  = text(0.02,y-9*dy/8,    TabDat.hdr{3,1});              Hs = [Hs,h];
    h  = text(0.08,y-9*dy/8,    TabDat.hdr{3,2});              Hs = [Hs,h];
    
    h = text(0.22,y, [TabDat.hdr{1,3} '-level'],'FontSize',FS(9));    Hc = [Hc,h];
    h = line([0.14,0.44],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r'); Hc = [Hc,h];
    h  = text(0.15,y-9*dy/8,    TabDat.hdr{3,3});              Hc = [Hc,h];
    h  = text(0.24,y-9*dy/8,    TabDat.hdr{3,4});              Hc = [Hc,h];
    h  = text(0.34,y-9*dy/8,    TabDat.hdr{3,5});              Hc = [Hc,h];
    h  = text(0.39,y-9*dy/8,    TabDat.hdr{3,6});              Hc = [Hc,h];
    
    h = text(0.64,y, [TabDat.hdr{1,7} '-level'],'FontSize',FS(9));    Hp = [Hp,h];
    h = line([0.48,0.88],[1,1]*(y-dy/4),'LineWidth',0.5,'Color','r'); Hp = [Hp,h];
    h  = text(0.49,y-9*dy/8,    TabDat.hdr{3,7});              Hp = [Hp,h];
    h  = text(0.58,y-9*dy/8,    TabDat.hdr{3,8});              Hp = [Hp,h];
    h  = text(0.67,y-9*dy/8,    TabDat.hdr{3,9});              Hp = [Hp,h];
    h  = text(0.75,y-9*dy/8,    TabDat.hdr{3,10});             Hp = [Hp,h];
    h  = text(0.82,y-9*dy/8,    TabDat.hdr{3,11});             Hp = [Hp,h];
    
    text(0.92,y - dy/2,TabDat.hdr{3,12},'Fontsize',FS(8));

    %-Move to next vertical position marker
    %----------------------------------------------------------------------
    y     = y - 7*dy/4;
    line([0 1],[y y],'LineWidth',1,'Color','r')
    y     = y - 5*dy/4;
    y0    = y;

    %-Table filtering note
    %----------------------------------------------------------------------
    text(0.5,4,TabDat.str,'HorizontalAlignment','Center',...
        'FontName',PF.helvetica,'FontSize',FS(8),'FontAngle','Italic')

    %-Footnote with SPM parameters (if classical inference)
    %----------------------------------------------------------------------
    line([0 1],[0.01 0.01],'LineWidth',1,'Color','r')
    if ~isempty(TabDat.ftr)
        set(gca,'DefaultTextFontName',PF.helvetica,...
            'DefaultTextInterpreter','None','DefaultTextFontSize',FS(8))
        
        fx = repmat([0 0.5],ceil(size(TabDat.ftr,1)/2),1);
        fy = repmat((1:ceil(size(TabDat.ftr,1)/2))',1,2);
        for i=1:size(TabDat.ftr,1)
            text(fx(i),-fy(i)*dy,sprintf(TabDat.ftr{i,1},TabDat.ftr{i,2}),...
                'UserData',TabDat.ftr{i,2},...
                'ButtonDownFcn','get(gcbo,''UserData'')');
        end
    end
    
    %-Characterize excursion set in terms of maxima
    % (sorted on Z values and grouped by regions)
    %======================================================================
    if isempty(TabDat.dat)
        text(0.5,y-6*dy,'no suprathreshold clusters',...
            'HorizontalAlignment','Center',...
            'FontAngle','Italic','FontWeight','Bold',...
            'FontSize',FS(16),'Color',[1,1,1]*.5);
        return
    end
    
    %-Table proper
    %======================================================================

    %-Column Locations
    %----------------------------------------------------------------------
    tCol = [ 0.01      0.08 ...                                %-Set
             0.15      0.24      0.33      0.39 ...            %-Cluster
             0.49      0.58      0.65      0.74      0.83 ...  %-Peak
             0.92];                                            %-XYZ
    
    %-Pagination variables
    %----------------------------------------------------------------------
    hPage = [];
    set(gca,'DefaultTextFontName',PF.courier,'DefaultTextFontSize',FS(7));

    %-Set-level p values {c} - do not display if reporting a single cluster
    %----------------------------------------------------------------------
    if isempty(TabDat.dat{1,1}) % Pc
        set(Hs,'Visible','off');
    end
    
    if TabDat.dat{1,2} > 1 % c
        h     = text(tCol(1),y,sprintf(TabDat.fmt{1},TabDat.dat{1,1}),...
                    'FontWeight','Bold', 'UserData',TabDat.dat{1,1},...
                    'ButtonDownFcn','get(gcbo,''UserData'')');
        hPage = [hPage, h];
        h     = text(tCol(2),y,sprintf(TabDat.fmt{2},TabDat.dat{1,2}),...
                    'FontWeight','Bold', 'UserData',TabDat.dat{1,2},...
                    'ButtonDownFcn','get(gcbo,''UserData'')');
        hPage = [hPage, h];
    else
        set(Hs,'Visible','off');
    end
    
    %-Cluster and local maxima p-values & statistics
    %----------------------------------------------------------------------
    HlistXYZ   = [];
    HlistClust = [];
    for i=1:size(TabDat.dat,1)
        
        %-Paginate if necessary
        %------------------------------------------------------------------
        if y < dy
            h = text(0.5,-5*dy,...
                sprintf('Page %d',spm_figure('#page',Fgraph)),...
                        'FontName',PF.helvetica,'FontAngle','Italic',...
                        'FontSize',FS(8));
            spm_figure('NewPage',[hPage,h])
            hPage = [];
            y     = y0;
        end
        
        %-Print cluster and maximum peak-level p values
        %------------------------------------------------------------------
        if  ~isempty(TabDat.dat{i,5}), fw = 'Bold'; else, fw = 'Normal'; end
        
        for k=3:11
            h = text(tCol(k),y,sprintf(TabDat.fmt{k},TabDat.dat{i,k}),...
                     'FontWeight',fw,...
                     'UserData',TabDat.dat{i,k},...
                     'ButtonDownFcn','get(gcbo,''UserData'')');
            hPage = [hPage, h];
            if k == 5
                HlistClust = [HlistClust, h];
                set(h,'UserData',struct('k',TabDat.dat{i,k},'XYZmm',TabDat.dat{i,12}));
                set(h,'ButtonDownFcn','getfield(get(gcbo,''UserData''),''k'')');
            end
        end
        
        % Specifically changed so it properly finds hMIPax
        %------------------------------------------------------------------
        tXYZmm = TabDat.dat{i,12};
        BDFcn  = [...
            'spm_mip_ui(''SetCoords'',get(gcbo,''UserData''),',...
                'findobj(''tag'',''hMIPax''));'];
        BDFcn = 'spm_XYZreg(''SetCoords'',get(gcbo,''UserData''),hReg,1);';
        h = text(tCol(12),y,sprintf(TabDat.fmt{12},tXYZmm),...
            'FontWeight',fw,...
            'Tag','ListXYZ',...
            'ButtonDownFcn',BDFcn,...
            'Interruptible','off',...
            'BusyAction','Cancel',...
            'UserData',tXYZmm);

        HlistXYZ = [HlistXYZ, h];
        hPage  = [hPage, h];
        y      = y - dy;
    end
    
    %-Number and register last page (if paginated)
    %----------------------------------------------------------------------
    if spm_figure('#page',Fgraph)>1
        h = text(0.5,-5*dy,sprintf('Page %d/%d',spm_figure('#page',Fgraph)*[1,1]),...
            'FontName',PF.helvetica,'FontSize',FS(8),'FontAngle','Italic');
        spm_figure('NewPage',[hPage,h])
    end
end