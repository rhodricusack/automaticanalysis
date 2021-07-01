function fig = meeg_diagnostics_CF(data,diag,varargin)
MAXCHANTOPLOT = 8; % maximum numbr of seperate figures as well as seperate subplots

if nargin >= 3, figtitle = varargin{1}; else, figtitle = 'Sample'; end
if nargin >= 4, savepath = varargin{2}; else, savepath = ''; end
if ~isfield(diag,'parameter'), diag.parameter = 'crsspctrm'; end

if ~iscell(data), data = {data}; end

if (ndims(data{1}.(diag.parameter)) > 3 && ~any(strcmp(strsplit(data{1}.dimord,'_'),'time'))) || ndims(data{1}.(diag.parameter)) > 4
    aas_log([],false,'WARNING: visualising data with more than 3D+time is not yet implemented')
    return
end

plotcfg.parameter = diag.parameter;
plotcfg.latency = diag.snapshottwoi./1000; % second

% tweak the data into TFR
if isfield(data{1},'labelcmb')
    figName = unique(data{1}.labelcmb(:,1))';
    if numel(unique(data{1}.labelcmb(:,2))) <= MAXCHANTOPLOT
        plotcfg.channels = unique(data{1}.labelcmb(:,2)); 
    end
elseif isfield(data{1},'label')
    figName = unique(data{1}.label)';
    if numel(data{1}.label) < 4 % plot single channels
        plotcfg.channels = unique(data{1}.label);
    end
end
cf = cellfun(@(x) cf2tf(diag,x), data,'UniformOutput',false);
plotcfg.layout = ft_prepare_layout([],cf{1}(1));

% plot as TFR
if numel(cf{1}) > MAXCHANTOPLOT, return; end
for p = 1:numel(cf{1})
    fignameind = min([numel(figName),p]);
    
    tf = cellfun(@(x) x(p), cf, 'UniformOutput',false);

    fig(p) = meeg_plot(plotcfg,tf);    
    
    ftit = figtitle;
    if ~isempty(figName{fignameind}), ftit = [ftit ': _' figName{fignameind}]; end
    set(fig(p),'Name',ftit)
    
    if nargin == 4 && ~isempty(savepath)
        figFn = savepath;
        if ~isempty(figName{fignameind}), figFn = [figFn '_' figName{fignameind}]; end
        print(fig(p),'-noui',[figFn '_multiplot.jpg'],'-djpeg','-r300');
        close(fig(p));
    end
end
end

function tf = cf2tf(diag,data)
TFDIMS = {'freq' 'rpt' 'rpttap'};
dims = strsplit(data.dimord,'_'); 
dims(1) = []; % not for chan/chancmb
dims(strcmp(dims,'time')) = []; % not for time, if exists
tf = data;
tf.dimord = 'chan';
for d = 1:numel(dims)
    tf.(TFDIMS{d}) = data.(dims{d});
    tf.dimord = strjoin([tf.dimord TFDIMS(d)],'_');
end
tf = rmfield(tf,setdiff(dims,TFDIMS));
if isfield(tf,'time'), tf.dimord = strjoin({tf.dimord 'time'},'_'); end

if isfield(data,'labelcmb')
    dat = tf; dat.label = {''}; clear tf;
    chans = unique(dat.labelcmb(:,1))';
    tf(1:numel(chans)) = dat;
    for ch = 1:numel(chans)
        ind = strcmp(tf(ch).labelcmb(:,1),chans{ch});
        tf(ch).label = union(tf(ch).labelcmb(ind,2),getedgeelec(tf(ch).elec),'stable'); % ensure proper arrangement of channels
        tf(ch).(diag.parameter)(~ind,:,:,:) = [];
        tf(ch).(diag.parameter)(end+1:numel(tf(ch).label),:,:,:) = NaN;
        if isfield(dat,'stat')
            tf(ch).stat.label = tf(ch).label;
            tf(ch).stat = rmfield(tf(ch).stat,'labelcmb');
            statfields = reshape(intersect(fieldnames(dat.stat),{'prob', 'stat' 'mask' 'posclusterslabelmat' 'negclusterslabelmat'}),1,[]);
            for stf = statfields
                tf(ch).stat.(stf{1})(~ind,:,:,:) = [];
                if islogical(tf(ch).stat.(stf{1})), tf(ch).stat.(stf{1})(end+1:numel(tf(ch).label),:,:,:) = false;
                else, tf(ch).stat.(stf{1})(end+1:numel(tf(ch).label),:,:,:) = NaN; end
            end
        end
    end
    tf = rmfield(tf,'labelcmb');
end
end

function ee = getedgeelec(elec)
e1 = min(elec.elecpos);
e2 = max(elec.elecpos);
ee = {...
    elec.label{elec.elecpos(:,2) == e2(2)} ...
    elec.label{elec.elecpos(:,2) == e1(2)} ...
    elec.label{elec.elecpos(:,1) == e2(1)} ...
    elec.label{elec.elecpos(:,1) == e1(1)} ...
    };
end