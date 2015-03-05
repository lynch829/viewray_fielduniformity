function varargout = UnitTest(varargin)
% UnitTest executes the unit tests for this application, and can be called 
% either independently (when testing just the latest version) or via 
% UnitTestHarness (when testing for regressions between versions).  Either 
% two or three input arguments can be passed to UnitTest as described 
% below.
%
% The following variables are required for proper execution: 
%   varargin{1}: string containing the path to the main function
%   varargin{2}: string containing the path to the test data
%   varargin{3} (optional): structure containing reference data to be used
%       for comparison.  If not provided, it is assumed that this version
%       is the reference and therefore all comparison tests will "Pass".
%
% The following variables are returned upon succesful completion:
%   varargout{1}: cell array of strings containing preamble text that
%       summarizes the test, where each cell is a line. This text will
%       precede the results table in the report.
%   varargout{2}: n x 3 cell array of strings containing the test ID in
%       the first column, name in the second, and result (Pass/Fail or 
%       numerical values typically) of the test in the third.
%   varargout{3}: cell array of strings containing footnotes referenced by
%       the tests, where each cell is a line.  This text will follow the
%       results table in the report.
%   varargout{4} (optional): structure containing reference data created by 
%       executing this version.  This structure can be passed back into 
%       subsequent executions of UnitTest as varargin{3} to compare results
%       between versions (or to a priori validated reference data).

%% Initialize Unit Testing
% Initialize static test result text variables
pass = 'Pass';
fail = 'Fail';
unk = 'N/A';

% Check if MATLAB can find CalcGamma (used by the unit tests)
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event('The CalcGamma submodule does not exist in the path.', ...
        'ERROR');
end

% Initialize preamble text
preamble = {
    '| Input Data | Value |'
    '|------------|-------|'
};

% Initialize results cell array
results = cell(0,3);

% Initialize footnotes cell array
footnotes = cell(0,1);

%% TEST 1/2: Application Loads Successfully, Time
%
% DESCRIPTION: This unit test attempts to execute the main application
%   executable and times how long it takes.  This test also verifies that
%   errors are present if the required submodules do not exist.
%
% RELEVANT REQUIREMENTS: U001, F001, P001
%
% INPUT DATA: No input data required
%
% CONDITION A (+): With the appropriate submodules present, attempt to open
%   the application and verify that it loads without error in the required
%   time.
%
% CONDITION B (-): With the snc_extract submodule missing, attempt to open
%   the application and verify that it throws an error

% Change to directory of version being tested
cd(varargin{1});

% Start with fail
pf = fail;

% Attempt to open application without submodule
try
    FieldUniformity('unitParseSNCprm');
catch
    pf = pass;
end

% Close all figures
close all force;

% Open application again with submodule, this time storing figure handle
try
    t = tic;
    h = FieldUniformity;
    time = sprintf('%0.1f sec', toc(t));
    if strcmp(pf, pass)
        pf = pass;
    end
catch
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Set unit test flag to 1 (to avoid uigetfile/questdlg/user input)
data.unitflag = 1; 

% Compute numeric version (equal to major * 10000 + minor * 100 + bug)
c = regexp(data.version, '^([0-9]+)\.([0-9]+)\.*([0-9]*)', 'tokens');
version = str2double(c{1}{1})*10000 + str2double(c{1}{2})*100 + ...
    max(str2double(c{1}{3}),0);

% Add version to results
results{size(results,1)+1,1} = 'ID';
results{size(results,1),2} = 'Test Case';
results{size(results,1),3} = sprintf('Version&nbsp;%s', data.version);

% Update guidata
guidata(h, data);

% Add application load result
results{size(results,1)+1,1} = '1';
results{size(results,1),2} = 'Application Loads Successfully';
results{size(results,1),3} = pf;

% Add application load time
results{size(results,1)+1,1} = '2';
results{size(results,1),2} = 'Application Load Time<sup>1</sup>';
results{size(results,1),3} = time;
footnotes{length(footnotes)+1} = ['<sup>1</sup>Prior to Version 1.1 ', ...
    'only the 27.3 cm x 27.3 cm reference profile existed'];

%% TEST 3/4: Code Analyzer Messages, Cumulative Cyclomatic Complexity
%
% DESCRIPTION: This unit test uses the checkcode() MATLAB function to check
%   each function used by the application and return any Code Analyzer
%   messages that result.  The cumulative cyclomatic complexity is also
%   computed for each function and summed to determine the total
%   application complexity.  Although this test does not reference any
%   particular requirements, it is used during development to help identify
%   high risk code.
%
% RELEVANT REQUIREMENTS: none 
%
% INPUT DATA: No input data required
%
% CONDITION A (+): Report any code analyzer messages for all functions
%   called by FieldUniformity
%
% CONDITION B (+): Report the cumulative cyclomatic complexity for all
%   functions called by FieldUniformity

% Search for required functions
fList = matlab.codetools.requiredFilesAndProducts('FieldUniformity.m');

% Initialize complexity and messages counters
comp = 0;
mess = 0;

% Loop through each dependency
for i = 1:length(fList)
    
    % Execute checkcode
    inform = checkcode(fList{i}, '-cyc');
    
    % Loop through results
    for j = 1:length(inform)
       
        % Check for McCabe complexity output
        c = regexp(inform(j).message, ...
            '^The McCabe complexity .+ is ([0-9]+)\.$', 'tokens');
        
        % If regular expression was found
        if ~isempty(c)
            
            % Add complexity
            comp = comp + str2double(c{1});
            
        else
            
            % If not an invalid code message
            if ~strncmp(inform(j).message, 'Filename', 8)
                
                % Log message
                Event(sprintf('%s in %s', inform(j).message, fList{i}), ...
                    'CHCK');

                % Add as code analyzer message
                mess = mess + 1;
            end
        end
        
    end
end

% Add code analyzer messages counter to results
results{size(results,1)+1,1} = '3';
results{size(results,1),2} = 'Code Analyzer Messages';
results{size(results,1),3} = sprintf('%i', mess);

% Add complexity results
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Cumulative Cyclomatic Complexity';
results{size(results,1),3} = sprintf('%i', comp);

%% TEST 5: Reference Data Loads Successfully
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100

    % Execute LoadProfilerReference in try/catch statement
    try
        pf = pass;
        LoadProfilerDICOMReference(data.references, '90');
    catch
        
        % If it errors, record fail
        pf = fail;
    end
  
% If version < 1.1.0    
else
    
    % Execute LoadReferenceProfiles in try/catch statement
    try
        pf = pass;
        LoadReferenceProfiles(...
            'AP_27P3X27P3_PlaneDose_Vertical_Isocenter.dcm');
    catch
        
        % If it errors, record fail
        pf = fail;
    end
end

% Add success message
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Reference Data Loads Successfully';
results{size(results,1),3} = pf;


%% TEST 6/7: Reference Data Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.refdata, varargin{3}.refdata)

            % Record pass
            xpf = pass;
            ypf = pass;
        else
            
            % Record fail
            xpf = fail;
            ypf = pass;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.refdata = data.refdata;

        % Assume pass
        xpf = pass;
        ypf = pass;

        % Add reference profiles to preamble
        preamble{length(preamble)+1} = ['| Reference&nbsp;Data | ', ...
            data.references{1}, '<br>', strjoin(data.references(2:end), ...
            '<br>'), ' |'];
    end
    
% If version < 1.1.0    
else
    
    % If reference data exists
    if nargin == 3

        % Compute MLC X gamma using 1%/0.1 mm and global method
        target.start = data.refX(1,1)/10;
        target.width = (data.refX(1,2)-data.refX(1,1))/10;
        target.data = data.refX(2,:)/max(data.refX(2,:));
        ref.start = varargin{3}.refdata.ydata(1,1);
        ref.width = varargin{3}.refdata.ydata(1,2) - ...
            varargin{3}.refdata.ydata(1,1);
        ref.data = varargin{3}.refdata.ydata(3,:)/...
            max(varargin{3}.refdata.ydata(3,:));
        gamma = CalcGamma(ref, target, 1, 0.01, 0);

        % If the gamma rate is less than one
        if max(gamma) < 1

            % Record pass
            xpf = pass;
        else
            
            % Record fail
            xpf = fail;
        end

        % Compute MLC Y gamma using 1%/0.1 mm and global method
        target.start = data.refY(1,1)/10;
        target.width = (data.refY(1,2)-data.refY(1,1))/10;
        target.data = data.refY(2,:)/max(data.refY(2,:));
        ref.start = varargin{3}.refdata.xdata(1,1);
        ref.width = varargin{3}.refdata.xdata(1,2) - ...
            varargin{3}.refdata.xdata(1,1);
        ref.data = varargin{3}.refdata.xdata(3,:)/...
            max(varargin{3}.refdata.xdata(3,:));
        gamma = CalcGamma(ref, target, 1, 0.01, 0);

        % If the gamma rate is less than one
        if max(gamma) < 1

            % Record pass
            ypf = pass;
        else
            
            % Record fail
            ypf = fail;
        end

    % Otherwise, no reference data exists
    else
        xpf = unk;
        ypf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '6';
results{size(results,1),2} = 'Reference MLC X Data within 1%/0.1 mm';
results{size(results,1),3} = xpf;

% Add result with footnote
results{size(results,1)+1,1} = '7';
results{size(results,1),2} = 'Reference MLC Y Data within 1%/0.1 mm<sup>2</sup>';
results{size(results,1),3} = ypf;
footnotes{length(footnotes)+1} = ['<sup>2</sup>[#10](../issues/10) ', ...
    'In Version 1.0 a bug was identified where MLC Y T&G effect was not', ...
    ' accounted for in the reference data'];

%% TEST 8/9: H1 Browse Loads Data Successfully/Load Time
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 browse button
callback = get(data.h1browse, 'Callback');

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Force specific gamma criteria (3%/1mm)
data.abs = 3;

% If version >= 1.1.0
if version >= 010100
    
    % Store DTA in cm
    data.dta = 0.1;
else
    
    % Store DTA in mm
    data.dta = 1;
end

% Add gamma criteria to preamble
preamble{length(preamble)+1} = '| Gamma Criteria | 3%/1mm |';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    pf = pass;
    callback(data.h1browse, data);
catch

    % If it errors, record fail
    pf = fail;
end

% Record completion time
time = sprintf('%0.1f sec', toc(t));

% Add result
results{size(results,1)+1,1} = '8';
results{size(results,1),2} = 'H1 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '9';
results{size(results,1),2} = 'Browse Callback Load Time';
results{size(results,1),3} = time;

%% TEST 10: MLC X Profile Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ydata(1,:), varargin{3}.ydata(1,:)) && ...
                isequal(data.h1results.ydata(2,:), varargin{3}.ydata(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ydata = data.h1results.ydata;

        % Assume pass
        pf = pass;

        % Add test data to preamble
        preamble{length(preamble)+1} = sprintf('| Measured Data | %s |', ...
            data.unitname);
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if isequal(data.h1X(1,:)/10, varargin{3}.ydata(1,:)) && ...
                max(abs(data.h1X(2,:) - varargin{3}.ydata(2,:))) < 0.001

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '10';
results{size(results,1),2} = 'MLC X Profile within 0.1%';
results{size(results,1),3} = pf;

%% TEST 11: MLC Y Profile Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.xdata(1,:), varargin{3}.xdata(1,:)) && ...
                isequal(data.h1results.xdata(2,:), varargin{3}.xdata(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.xdata = data.h1results.xdata;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if isequal(data.h1Y(1,:)/10, varargin{3}.xdata(1,:)) && ...
                max(abs(data.h1Y(2,:) - varargin{3}.xdata(2,:))) < 0.001

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '11';
results{size(results,1),2} = 'MLC Y Profile within 0.1%';
results{size(results,1),3} = pf;

%% TEST 12: Positive Diagonal Profile Identical (> 1.1.0)
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.pdiag(1,:), varargin{3}.pdiag(1,:)) && ...
                isequal(data.h1results.pdiag(2,:), varargin{3}.pdiag(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.pdiag = data.h1results.pdiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '12';
results{size(results,1),2} = 'Positive Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;
footnotes{length(footnotes)+1} = ['<sup>3</sup>Prior to Version 1.1 ', ...
    'diagonal profiles were not available'];

%% TEST 13: Negative Diagonal Profile Identical (>1.1.0)
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ndiag(1,:), varargin{3}.ndiag(1,:)) && ...
                isequal(data.h1results.ndiag(2,:), varargin{3}.ndiag(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ndiag = data.h1results.ndiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result
results{size(results,1)+1,1} = '13';
results{size(results,1),2} = 'Negative Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 14: Timing Profile Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.tdata(1,:), varargin{3}.tdata(1,:)) && ...
                isequal(data.h1results.tdata(2,:), varargin{3}.tdata(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.tdata = data.h1results.tdata;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if max(abs(data.h1T(2,2:end)/max(data.h1T(2,:)) - ...
                varargin{3}.tdata(2,2:end)/max(varargin{3}.tdata(2,:)))) ...
                < 0.001

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end

end

% Add result
results{size(results,1)+1,1} = '14';
results{size(results,1),2} = 'Timing Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 15: MLC X Gamma Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ygamma(1,:), varargin{3}.ygamma(1,:)) && ...
                isequal(data.h1results.ygamma(2,:), varargin{3}.ygamma(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ygamma = data.h1results.ygamma;

        % Assume pass
        pf = pass;

    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1
        if max(abs(data.h1X(3,:) - varargin{3}.ygamma(2,:)) .* ...
                (abs(varargin{3}.ydata(1,:)) < 15)) < 0.1

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '15';
results{size(results,1),2} = 'MLC X Gamma within 0.1';
results{size(results,1),3} = pf;

%% TEST 16: MLC Y Gamma Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.xgamma(1,:), varargin{3}.xgamma(1,:)) && ...
                isequal(data.h1results.xgamma(2,:), varargin{3}.xgamma(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.xgamma = data.h1results.xgamma;

        % Assume pass
        pf = pass;

    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % Remove interpolated values
        h1Y = [data.h1Y(3,1:31) data.h1Y(3,33) ...
            data.h1Y(3,35:end)];
        
        % If current value equals the reference to within 0.1
        if max(abs(h1Y - varargin{3}.xgamma(2,:)) .* ...
                (abs(varargin{3}.xgamma(1,:)) < 15)) < 0.1

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '16';
results{size(results,1),2} = 'MLC Y Gamma within 0.1<sup>2</sup>';
results{size(results,1),3} = pf;

%% TEST 17: Positive Diagonal Gamma Identical (> 1.1.0)
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.pgamma(1,:), varargin{3}.pgamma(1,:)) && ...
                isequal(data.h1results.pgamma(2,:), varargin{3}.pgamma(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.pgamma = data.h1results.pgamma;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '17';
results{size(results,1),2} = 'Positive Diagonal Gamma within 0.1<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 18: Negative Diagonal Gamma Identical (> 1.1.0)
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ngamma(1,:), varargin{3}.ngamma(1,:)) && ...
                isequal(data.h1results.ngamma(2,:), varargin{3}.ngamma(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ngamma = data.h1results.ngamma;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '18';
results{size(results,1),2} = 'Negative Diagonal Gamma within 0.1<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 19: Statistics Identical
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(textscan(data.h1table.Data{2,2}, '%f'), ...
                varargin{3}.statbot) && ...
                isequal(textscan(data.h1table.Data{3,2}, '%f'), ...
                varargin{3}.statxfwhm) && ...
                isequal(textscan(data.h1table.Data{4,2}, '%f'), ...
                varargin{3}.statxflat) && ...
                isequal(textscan(data.h1table.Data{5,2}, '%f'), ...
                varargin{3}.statxsym) && ...
                isequal(textscan(data.h1table.Data{6,2}, '%f'), ...
                varargin{3}.statyfwhm) && ...
                isequal(textscan(data.h1table.Data{7,2}, '%f'), ...
                varargin{3}.statyflat) && ...
                isequal(textscan(data.h1table.Data{8,2}, '%f'), ...
                varargin{3}.statysym)

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.statbot = textscan(data.h1table.Data{2,2}, '%f');
        reference.statxfwhm = textscan(data.h1table.Data{3,2}, '%f');
        reference.statxflat = textscan(data.h1table.Data{4,2}, '%f');
        reference.statxsym = textscan(data.h1table.Data{5,2}, '%f');
        reference.statyfwhm = textscan(data.h1table.Data{6,2}, '%f');
        reference.statyflat = textscan(data.h1table.Data{7,2}, '%f');
        reference.statysym = textscan(data.h1table.Data{8,2}, '%f');

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference (within 0.1 sec/0.1 mm/0.1%)
        if abs(cell2mat(textscan(data.h1table.Data{4,2}, '%f')) - ...
                varargin{3}.statbot{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{8,2}, '%f')) - ...
                varargin{3}.statxfwhm{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{9,2}, '%f')) - ...
                varargin{3}.statxflat{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{10,2}, '%f')) - ...
                varargin{3}.statxsym{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{14,2}, '%f')) - ...
                varargin{3}.statyfwhm{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{15,2}, '%f')) - ...
                varargin{3}.statyflat{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{16,2}, '%f')) - ...
                varargin{3}.statysym{1}) < 0.1

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end

end

% Add result with footnote
results{size(results,1)+1,1} = '19';
results{size(results,1),2} = 'Statistics within 0.1 sec/mm/%<sup>4</sup>';
results{size(results,1),3} = pf;
footnotes{length(footnotes)+1} = ['<sup>4</sup>[#11](../issues/11) In ', ...
    'Version 1.1.0 a bug was identified where flatness was computed', ...
    ' incorrectly'];

%% TEST 20: H1 Figures Functional
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 display dropdown
callback = get(data.h1display, 'Callback');

% Execute callbacks in try/catch statement
try
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h1display.String)
        
        % Set value
        data.h1display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h1display, data);
    end
catch
    
    % If callback fails, record failure
    pf = fail; 
end

% Add result with footnote
results{size(results,1)+1,1} = '20';
results{size(results,1),2} = 'H1 Figure Display Functional';
results{size(results,1),3} = pf;

%% TEST 21/22: H2/H3 Browse Loads Data Successfully
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Retrieve callback to H2 browse button
callback = get(data.h2browse, 'Callback');

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h2browse, data);
catch

    % If callback throws error, record fail
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '21';
results{size(results,1),2} = 'H2 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

% Retrieve callback to H3 browse button
callback = get(data.h3browse, 'Callback');

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h3browse, data);
catch

    % If callback throws error, record fail
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '22';
results{size(results,1),2} = 'H3 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

%% TEST 23/24: H2/H3 Figures Functional
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H2 display dropdown
callback = get(data.h2display, 'Callback');

% Execute callbacks in try/catch statement
try
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h2display.String)
        
        % Set value
        data.h2display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h2display, data);
    end
catch
    
    % If callback fails, record failure
    pf = fail; 
end

% Add result
results{size(results,1)+1,1} = '23';
results{size(results,1),2} = 'H2 Figure Display Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H3 display dropdown
callback = get(data.h3display, 'Callback');

% Execute callbacks in try/catch statement
try
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h3display.String)
        
        % Set value
        data.h3display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h3display, data);
    end
catch
    
    % If callback fails, record failure
    pf = fail; 
end

% Add result
results{size(results,1)+1,1} = '24';
results{size(results,1),2} = 'H3 Figure Display Functional';
results{size(results,1),3} = pf;

%% TEST 25/26: Print Report Functional (> 1.1.0)
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% If version >= 1.1.0
if version >= 010100
    
    % Retrieve guidata
    data = guidata(h);

    % Retrieve callback to print button
    callback = get(data.print_button, 'Callback');

    % Execute callback in try/catch statement
    try
        % Start with pass
        pf = pass;
    
        % Start timer
        t = tic;
        
        % Execute callback
        callback(data.print_button, data);
    catch
        
        % If callback fails, record failure
        pf = fail; 
    end
    
    % Record completion time
    time = sprintf('%0.1f sec', toc(t)); 

% If version < 1.1.0
else
    
    % This feature does not exist
    pf = unk;
    time = unk;
end

% Add result
results{size(results,1)+1,1} = '25';
results{size(results,1),2} = 'Print Report Functional';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '26';
results{size(results,1),2} = 'Print Report Time';
results{size(results,1),3} = time;

%% TEST 27/28/29: Clear All Buttons Functional
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS: C001-C014 (assuming all prior unit tests are
%   completed with each test suite on each system)
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Retrieve guidata
data = guidata(h);

% Retrieve callback to H1 clear button
callback = get(data.h1clear, 'Callback');

% Execute callback in try/catch statement
try
    
    % Start with pass
    pf = pass;
    
    % Execute callback
    callback(data.h1clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '27';
results{size(results,1),2} = 'H1 Clear Button Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H1 clear button
callback = get(data.h2clear, 'Callback');

% Execute callback in try/catch statement
try
    
    % Start with pass
    pf = pass;
    
    % Execute callback
    callback(data.h2clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '28';
results{size(results,1),2} = 'H2 Clear Button Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H1 clear button
callback = get(data.h3clear, 'Callback');

% Execute callback in try/catch statement
try
    
    % Start with pass
    pf = pass;
    
    % Execute callback
    callback(data.h3clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '29';
results{size(results,1),2} = 'H3 Clear Button Functional';
results{size(results,1),3} = pf;

%% TEST 30: Documentation Exists
%
% DESCRIPTION: 
%
% RELEVANT REQUIREMENTS:
%
% INPUT DATA: No input data required
%
% CONDITION A (+): 
%
% CONDITION B (-): 

% Look for README.md
fid = fopen('README.md', 'r');

% If file handle was valid, record pass
if fid >= 3
    pf = pass;
else
    pf = fail;
end

% Close file handle
fclose(fid);

% Add result
results{size(results,1)+1,1} = '30';
results{size(results,1),2} = 'Documentation Exists';
results{size(results,1),3} = pf;

%% Finish up
% Close all figures
close all force;

% Store return variables
varargout{1} = preamble;
varargout{2} = results;
varargout{3} = footnotes;
if nargout == 4
    varargout{4} = reference;
end