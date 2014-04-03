% Automatic analysis - this file returns the names of levels of a domain.
% For example, if domain is 'subject', we return all the subject names. If
% the domain is 'session' we return the session names. As you add new
% domains, add the appropriate thing here.
%   domain='subject','session' etc
%   index= number of item
%
% Added by CW: 2014-04-02
%
function [names] = aas_getNames_bydomain(aap, domains)

if ~iscell(domains), domains = {domains}; end

for d = 1 : length(domains)
    
    switch (domains{d})
        
        case 'session'
            names{d} = {aap.acq_details.sessions.name};
            
        case 'subject'
            names{d} = {aap.acq_details.subjects.mriname};
            
        case 'study'
            names{d} = {aap.directory_conventions.analysisid};
            
        case {'diffusion_session', 'diffusion_session_bedpostx'}
            names{d} = {aap.acq_details.diffusion_sessions.name};
            
        otherwise
            aas_log(aap, 1, sprintf('Invalid domain %s, perhaps NYI in this function', domain));
    end
    
end

if length(names) == 1, names = names{1}; end