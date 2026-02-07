import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RotateCcw, Filter } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';

interface VoiceAgent {
  id: string;
  name: string;
  phone_number?: string;
  status?: string;
}

interface InboundNumber {
  id: string;
  phone_number: string;
  phone_label: string | null;
}

interface CallStatusSummaryProps {
  totalCalls: number;
  completed: number;
  failed: number;
  inProgress: number;
  voiceAgents: VoiceAgent[];
  inboundNumbers: InboundNumber[];
  selectedAgentId: string;
  selectedNumberId: string;
  onAgentChange: (agentId: string) => void;
  onNumberChange: (numberId: string) => void;
  onStatusClick?: (status: 'all' | 'completed' | 'failed' | 'inProgress') => void;
}

const CallStatusSummary: React.FC<CallStatusSummaryProps> = ({
  totalCalls,
  completed,
  failed,
  inProgress,
  voiceAgents,
  inboundNumbers,
  selectedAgentId,
  selectedNumberId,
  onAgentChange,
  onNumberChange,
  onStatusClick,
}) => {
  // Calculate percentages for the donut chart
  const total = totalCalls || 1;
  const completedPercent = (completed / total) * 100;
  const failedPercent = (failed / total) * 100;
  const inProgressPercent = (inProgress / total) * 100;

  // SVG donut chart configuration
  const size = 140;
  const strokeWidth = 22;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const center = size / 2;

  // Calculate stroke dasharray and offset for each segment
  const completedDash = (completedPercent / 100) * circumference;
  const failedDash = (failedPercent / 100) * circumference;
  const inProgressDash = (inProgressPercent / 100) * circumference;

  const completedOffset = 0;
  const failedOffset = -completedDash;
  const inProgressOffset = -(completedDash + failedDash);

  const handleStatusClick = (status: 'all' | 'completed' | 'failed' | 'inProgress') => {
    if (onStatusClick) {
      onStatusClick(status);
    }
  };

  // Completion rate
  const completionRate = totalCalls > 0 ? Math.round((completed / totalCalls) * 100) : 0;

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <RotateCcw className="w-5 h-5 text-primary" />
            <CardTitle className="text-foreground">Call Status Summary</CardTitle>
          </div>
          <span className="text-xs text-muted-foreground bg-muted/50 px-3 py-1 rounded-full">
            All time
          </span>
        </div>
        
        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center pt-4 border-t border-border">
          <div className="flex items-center gap-2 text-muted-foreground">
            <Filter className="w-4 h-4" />
            <span className="text-sm font-medium">Filters:</span>
          </div>
          <div className="flex flex-col sm:flex-row gap-4 flex-1">
            <div className="flex flex-col gap-2 min-w-[200px]">
              <Label htmlFor="agent-filter-summary" className="text-xs text-muted-foreground">
                Agent
              </Label>
              <Select value={selectedAgentId} onValueChange={onAgentChange}>
                <SelectTrigger id="agent-filter-summary">
                  <SelectValue placeholder="All Agents" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Agents</SelectItem>
                  {voiceAgents.map((agent) => (
                    <SelectItem key={agent.id} value={agent.id}>
                      {agent.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-2 min-w-[200px]">
              <Label htmlFor="number-filter-summary" className="text-xs text-muted-foreground">
                Phone Number
              </Label>
              <Select value={selectedNumberId} onValueChange={onNumberChange}>
                <SelectTrigger id="number-filter-summary">
                  <SelectValue placeholder="All Numbers" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Numbers</SelectItem>
                  {inboundNumbers.map((number) => (
                    <SelectItem key={number.id} value={number.id}>
                      {number.phone_number} {number.phone_label ? `(${number.phone_label})` : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col sm:flex-row items-center gap-8">
          {/* Donut Chart */}
          <div className="relative flex-shrink-0" style={{ width: size, height: size }}>
            <svg width={size} height={size} className="transform -rotate-90">
              {/* Background ring */}
              <circle
                cx={center}
                cy={center}
                r={radius}
                fill="none"
                stroke="currentColor"
                strokeWidth={strokeWidth}
                className="text-muted/30"
              />
              {/* Completed (green) */}
              {completed > 0 && (
                <circle
                  cx={center}
                  cy={center}
                  r={radius}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={strokeWidth}
                  strokeDasharray={`${completedDash} ${circumference}`}
                  strokeDashoffset={completedOffset}
                  className="text-emerald-500"
                  strokeLinecap="round"
                />
              )}
              {/* Failed (red) */}
              {failed > 0 && (
                <circle
                  cx={center}
                  cy={center}
                  r={radius}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={strokeWidth}
                  strokeDasharray={`${failedDash} ${circumference}`}
                  strokeDashoffset={failedOffset}
                  className="text-red-400"
                  strokeLinecap="round"
                />
              )}
              {/* In Progress (amber) */}
              {inProgress > 0 && (
                <circle
                  cx={center}
                  cy={center}
                  r={radius}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={strokeWidth}
                  strokeDasharray={`${inProgressDash} ${circumference}`}
                  strokeDashoffset={inProgressOffset}
                  className="text-amber-400"
                  strokeLinecap="round"
                />
              )}
            </svg>
            {/* Center text */}
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-2xl font-bold text-foreground">{completionRate}%</span>
              <span className="text-[10px] text-muted-foreground uppercase tracking-wider">Complete</span>
            </div>
          </div>

          {/* Legend - Clickable */}
          <div className="flex-1 space-y-2 w-full">
            <div 
              className="flex items-center gap-3 cursor-pointer hover:bg-muted/50 p-2.5 rounded-lg transition-colors"
              onClick={() => handleStatusClick('all')}
            >
              <div className="w-3.5 h-3.5 rounded-full bg-primary flex-shrink-0"></div>
              <div className="flex-1">
                <span className="text-sm font-medium text-foreground">Total Calls</span>
              </div>
              <span className="text-lg font-bold text-foreground font-mono">{totalCalls}</span>
            </div>
            <div 
              className="flex items-center gap-3 cursor-pointer hover:bg-muted/50 p-2.5 rounded-lg transition-colors"
              onClick={() => handleStatusClick('completed')}
            >
              <div className="w-3.5 h-3.5 rounded-full bg-emerald-500 flex-shrink-0"></div>
              <div className="flex-1">
                <span className="text-sm font-medium text-foreground">Completed</span>
                {totalCalls > 0 && (
                  <span className="text-xs text-muted-foreground ml-2">
                    ({Math.round((completed / totalCalls) * 100)}%)
                  </span>
                )}
              </div>
              <span className="text-lg font-bold text-foreground font-mono">{completed}</span>
            </div>
            <div 
              className="flex items-center gap-3 cursor-pointer hover:bg-muted/50 p-2.5 rounded-lg transition-colors"
              onClick={() => handleStatusClick('failed')}
            >
              <div className="w-3.5 h-3.5 rounded-full bg-red-400 flex-shrink-0"></div>
              <div className="flex-1">
                <span className="text-sm font-medium text-foreground">Failed / Missed</span>
                {totalCalls > 0 && (
                  <span className="text-xs text-muted-foreground ml-2">
                    ({Math.round((failed / totalCalls) * 100)}%)
                  </span>
                )}
              </div>
              <span className="text-lg font-bold text-foreground font-mono">{failed}</span>
            </div>
            <div 
              className="flex items-center gap-3 cursor-pointer hover:bg-muted/50 p-2.5 rounded-lg transition-colors"
              onClick={() => handleStatusClick('inProgress')}
            >
              <div className="w-3.5 h-3.5 rounded-full bg-amber-400 flex-shrink-0"></div>
              <div className="flex-1">
                <span className="text-sm font-medium text-foreground">In Progress</span>
                {totalCalls > 0 && (
                  <span className="text-xs text-muted-foreground ml-2">
                    ({Math.round((inProgress / totalCalls) * 100)}%)
                  </span>
                )}
              </div>
              <span className="text-lg font-bold text-foreground font-mono">{inProgress}</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default CallStatusSummary;
