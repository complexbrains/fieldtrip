function data = append_common(cfg, varargin)

% APPEND_COMMON is used for concatenating raw, timelock or freq data
%
% See FT_APPENDDATA, T_APPENDTIMELOCK, FT_APPENDFREQ

% Copyright (C) 2017, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% the general bookkeeping and the correct specification of the cfg
% should be taken care of by the calling function

% these are being dealt with explicitly, depending on cfg.appenddim
hastime       = isfield(varargin{1}, 'time');
hasfreq       = isfield(varargin{1}, 'freq');
hastrialinfo  = isfield(varargin{1}, 'trialinfo');
hassampleinfo = isfield(varargin{1}, 'sampleinfo');
for i=2:numel(varargin)
  hastime       = hastime       && isfield(varargin{i}, 'time');
  hasfreq       = hasfreq       && isfield(varargin{i}, 'freq');
  hastrialinfo  = hastrialinfo  && isfield(varargin{i}, 'trialinfo');
  hassampleinfo = hassampleinfo && isfield(varargin{i}, 'sampleinfo');
end

switch cfg.appenddim
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'chan'
    assert(checkchan(varargin{:}, 'unique'));
    % remember the original channel labels in each input
    oldlabel = cell(size(varargin));
    for i=1:numel(varargin)
      oldlabel{i} =  varargin{i}.label;
    end
    
    % determine the union of all input data
    tmpcfg = keepfields(cfg, {'tolerance', 'channel'});
    tmpcfg.select = 'union';
    [varargin{:}] = ft_selectdata(tmpcfg, varargin{:});
    for i=1:numel(varargin)
      [cfg, varargin{i}] = rollback_provenance(cfg, varargin{i});
    end
    
    % start with the union of all input data
    data = keepfields(varargin{1}, {'label', 'time', 'freq', 'dimord'});
    
    % keep the trialinfo and sampleinfo (when identical)
    fn = {'trialinfo' 'sampleinfo'};
    for i=1:numel(fn)
      keepfield = isfield(varargin{1}, fn{i});
      for j=1:numel(varargin)
        if ~isfield(varargin{j}, fn{i}) || ~isequal(varargin{j}.(fn{i}), varargin{1}.(fn{i}))
          keepfield = false;
          break
        end
      end
      if keepfield
        data.(fn{i}) = varargin{1}.(fn{i});
      end
    end % for each of the fields to keep
    
    for i=1:numel(cfg.parameter)
      dimsiz = getdimsiz(varargin{1}, cfg.parameter{i});
      switch getdimord(varargin{1}, cfg.parameter{i})
        case {'chan_time' 'chan_freq'}
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            chansel = match_str(varargin{j}.label, oldlabel{j});
            data.(cfg.parameter{i})(chansel,:) = varargin{j}.(cfg.parameter{i})(chansel,:);
          end
          
        case {'rpt_chan_time' 'subj_chan_time' 'rpt_chan_freq' 'subj_chan_freq'}
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            chansel = match_str(varargin{j}.label, oldlabel{j});
            data.(cfg.parameter{i})(:,chansel,:) = varargin{j}.(cfg.parameter{i})(:,chansel,:);
          end
          
        otherwise
          % do not concatenate this field
      end % switch
    end % for cfg.parameter
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case {'time' 'freq'}
    
    % remember the original axes in each input
    if hasfreq
      oldfreq = cell(size(varargin));
      for i=1:numel(varargin)
        oldfreq{i} = varargin{i}.freq;
      end
    end
    if hastime
      oldtime = cell(size(varargin));
      for i=1:numel(varargin)
        oldtime{i} =  varargin{i}.time;
      end
    end
    
    % determine the union of all input data
    tmpcfg = keepfields(cfg, {'tolerance', 'channel'});
    tmpcfg.select = 'union';
    [varargin{:}] = ft_selectdata(tmpcfg, varargin{:});
    for i=1:numel(varargin)
      [cfg, varargin{i}] = rollback_provenance(cfg, varargin{i});
    end
    
    % start with the union of all input data
    data = keepfields(varargin{1}, {'label', 'time', 'freq', 'dimord'});
    
    % keep the trialinfo (when identical)
    fn = {'trialinfo'};
    for i=1:numel(fn)
      keepfield = isfield(varargin{1}, fn{i});
      for j=1:numel(varargin)
        if ~isfield(varargin{j}, fn{i}) || ~isequal(varargin{j}.(fn{i}), varargin{1}.(fn{i}))
          keepfield = false;
          break
        end
      end
      if keepfield
        data.(fn{i}) = varargin{1}.(fn{i});
      end
    end % for each of the fields to keep
    
    for i=1:numel(cfg.parameter)
      dimsiz = getdimsiz(varargin{1}, cfg.parameter{i});
      switch getdimord(varargin{1}, cfg.parameter{i})
        case 'chan_time'
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            timesel = match_val(varargin{j}.time, oldtime{j});
            data.(cfg.parameter{i})(:,timesel) = varargin{j}.(cfg.parameter{i})(:,timesel);
          end
          
        case 'chan_freq'
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            freqsel = match_val(varargin{j}.freq, oldfreq{j});
            data.(cfg.parameter{i})(:,freqsel) = varargin{j}.(cfg.parameter{i})(:,freqsel);
          end
          
        case 'chan_freq_time'
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            freqsel = match_val(varargin{j}.freq, oldfreq{j});
            timesel = match_val(varargin{j}.time, oldtime{j});
            data.(cfg.parameter{i})(:,freqsel,timesel) = varargin{j}.(cfg.parameter{i})(:,freqsel,timesel);
          end
          
        case {'rpt_chan_time' 'subj_chan_time'}
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            timesel = match_val(varargin{j}.time, oldtime{j});
            data.(cfg.parameter{i})(:,:,timesel) = varargin{j}.(cfg.parameter{i})(:,:,timesel);
          end
          
        case {'rpt_chan_freq' 'rpttap_chan_freq' 'subj_chan_freq'}
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            freqsel = match_val(varargin{j}.freq, oldfreq{j});
            data.(cfg.parameter{i})(:,:,freqsel) = varargin{j}.(cfg.parameter{i})(:,:,freqsel);
          end
          
        case {'rpt_chan_freq_time' 'rpttap_chan_freq_time' 'subj_chan_freq_time'}
          data.(cfg.parameter{i}) = nan(dimsiz);
          for j=1:numel(varargin)
            freqsel = match_val(varargin{j}.freq, oldfreq{j});
            timesel = match_val(varargin{j}.time, oldtime{j});
            data.(cfg.parameter{i})(:,:,freqsel,timesel) = varargin{j}.(cfg.parameter{i})(:,:,freqsel,timesel);
          end
          
        otherwise
          % do not concatenate this field
          
      end % switch
    end % for cfg.parameter
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'rpt'
    % determine the intersection of all input data
    tmpcfg = keepfields(cfg, {'tolerance', 'channel'});
    tmpcfg.select = 'intersect';
    [varargin{:}] = ft_selectdata(tmpcfg, varargin{:});
    for i=1:numel(varargin)
      [cfg, varargin{i}] = rollback_provenance(cfg, varargin{i});
    end
    
    % start with the intersection of all input data
    data = keepfields(varargin{1}, {'label', 'time', 'freq', 'dimord'});
    if hastime, assert(numel(data.time)>0); end
    if hasfreq, assert(numel(data.freq)>0); end
    
    % also append these when present
    if hastrialinfo,  cfg.parameter{end+1} = 'trialinfo';  end
    if hassampleinfo, cfg.parameter{end+1} = 'sampleinfo'; end
    
    for i=1:numel(cfg.parameter)
      dimsiz = getdimsiz(varargin{1}, cfg.parameter{i});
      switch getdimord(varargin{1}, cfg.parameter{i})
        case {'chan_time' 'chan_freq'}
          dat = cell(size(varargin));
          for j=1:numel(varargin)
            dat{j} = reshape(varargin{j}.(cfg.parameter{i}), 1, dimsiz(1), dimsiz(2));
          end
          data.(cfg.parameter{i}) = cat(1, dat{:});
          
        case 'chan_freq_time'
          dat = cell(size(varargin));
          for j=1:numel(varargin)
            dat{j} = reshape(varargin{j}.(cfg.parameter{i}), 1, dimsiz(1), dimsiz(2), dimsiz(3));
          end
          data.(cfg.parameter{i}) = cat(1, dat{:});
          
        case {'rpt_chan_time' 'rpt_chan_freq' 'rpt_chan_freq_time' 'rpttap_chan_freq' 'rpttap_chan_freq_time' 'rpt_other'}
          dat = cell(size(varargin));
          for j=1:numel(varargin)
            dat{j} = varargin{j}.(cfg.parameter{i});
          end
          data.(cfg.parameter{i}) = cat(1, dat{:});
          
        otherwise
          % do not concatenate this field
          
      end % switch
    end % for cfg.parameter
    
  otherwise
    error('unsupported cfg.appenddim');
end

if isfield(data, 'dimord')
  dimtok = tokenize(data.dimord);
  if strcmp(cfg.appenddim, 'rpt') && ~any(strcmp(dimtok{1}, {'rpt', 'rpttap', 'subj'}))
    data.dimord = ['rpt_' data.dimord];
  end
end

hasgrad = false;
haselec = false;
hasopto = false;
for i=1:length(varargin)
  hasgrad = hasgrad || isfield(varargin{i}, 'grad');
  haselec = haselec || isfield(varargin{i}, 'elec');
  hasopto = hasopto || isfield(varargin{i}, 'opto');
end
if  hasgrad || haselec || hasopto
  % gather the sensor definitions from all inputs
  grad = cell(size(varargin));
  elec = cell(size(varargin));
  opto = cell(size(varargin));
  for j=1:length(varargin)
    if isfield(varargin{j}, 'elec')
      elec{j} = varargin{j}.elec;
    end
    if isfield(varargin{j}, 'grad')
      grad{j} = varargin{j}.grad;
    end
    if isfield(varargin{j}, 'opto')
      opto{j} = varargin{j}.opto;
    end
  end
  % see test_pull393.m for a description of the expected behavior
  if strcmp(cfg.appendsens, 'yes')
    fprintf('concatenating sensor information across input arguments\n');
    % append the sensor descriptions, skip the empty ones
    if hasgrad, data.grad = ft_appendsens([], grad{~cellfun(@isempty, grad)}); end
    if haselec, data.elec = ft_appendsens([], elec{~cellfun(@isempty, elec)}); end
    if hasopto, data.opto = ft_appendsens([], opto{~cellfun(@isempty, opto)}); end
  else
    % discard sensor information when it is inconsistent across the input arguments
    removegrad = any(cellfun(@isempty, grad));
    removeelec = any(cellfun(@isempty, elec));
    removeopto = any(cellfun(@isempty, opto));
    for j=2:length(varargin)
      removegrad = removegrad || ~isequaln(grad{j}, grad{1});
      removeelec = removeelec || ~isequaln(elec{j}, elec{1});
      removeopto = removeopto || ~isequaln(opto{j}, opto{1});
    end
    if hasgrad && ~removegrad, data.grad = grad{1}; end
    if haselec && ~removeelec, data.elec = elec{1}; end
    if hasopto && ~removeopto, data.opto = opto{1}; end
  end
end
