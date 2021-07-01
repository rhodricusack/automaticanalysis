classdef eboscClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end
    
    methods
        function obj = eboscClass(path,varargin)
            defaultAddToPath = false;
            defaultKeepInPath = false;
            
            argParse = inputParser;
            argParse.addRequired('path',@ischar);
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.addParameter('doKeepInPath',defaultKeepInPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});
            
            obj = obj@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,argParse.Results.doKeepInPath,{});
        end
        
        function load(obj)
            addpath(obj.toolPath);
            addpath(fullfile(obj.toolPath,'internal'));
            addpath(fullfile(obj.toolPath,'external','BOSC'));
            
            load@toolboxClass(obj)
        end
    end
end