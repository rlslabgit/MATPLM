function zoomAdaptiveLogScaleTicks(varargin)
% ZOOMADAPTIVELOGSCALETICKS - Make log scale ticks adapt to zooming
%
% zoomAdaptiveLogScaleTicks('on')
% Turns on the automatic adaptation of log scale ticks
% to user zooming for the current figure window
%
% zoomAdaptiveLogScaleTicks('off')
% Turns off the automatic adaptation of log scale ticks
% to user zooming for the current figure window
% 
% zoomAdaptiveLogScaleTicks('demo')
% Opens a demo figure window to play with


if (nargin>0)
   switch varargin{1}
      case 'demo'
         % Create demo values
         logVals = floor(now) - linspace(1169,0,15000)';
         values= randn(15000,1);
         % Show data with log scale ticks
         figure
         plot(logVals,values)
         yt = get(gca, 'YTick');
         set(gca, 'YTickLabel', round(exp(yt)));
         zoomAdaptiveLogScaleTicks('on')
      case 'xon'
         % Define a post zoom callback
         set(zoom(gcf),'ActionPostCallback', @adaptiveLogScaleXTicks);
         set(pan(gcf),'ActionPostCallback', @adaptiveLogScaleXTicks);
         set(rotate3d(gcf),'ActionPostCallback', @adaptiveLogScaleXTicks);
      case 'yon'
         set(zoom(gcf),'ActionPostCallback', @adaptiveLogScaleYTicks);
         set(pan(gcf),'ActionPostCallback', @adaptiveLogScaleYTicks);
         set(rotate3d(gcf),'ActionPostCallback', @adaptiveLogScaleYTicks);
      case 'off'
         % Delete the post zoom callback
         set(zoom(gcf),'ActionPostCallback', '');
         set(pan(gcf),'ActionPostCallback', '');
      otherwise
         figure(gcf)
   end
end


function adaptiveLogScaleXTicks(figureHandle,eventObjectHandle)
% Resetting x axis to automatic tick mark generation 
set(eventObjectHandle.Axes,'XTickMode','auto')
% using automaticallly generate log scale ticks
xt = get(gca, 'XTick');
set(gca, 'XTickLabel', round(exp(xt)));
 
function adaptiveLogScaleYTicks(figureHandle,eventObjectHandle)
% Resetting x axis to automatic tick mark generation 
set(eventObjectHandle.Axes,'YTickMode','auto')
% using automaticallly generate log scale ticks
yt = get(gca, 'YTick');
set(gca, 'YTickLabel', round(exp(yt)));

% Copyright (c) 2007, The MathWorks, Inc.
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the The MathWorks, Inc. nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
