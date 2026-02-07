import { Phone, Clock, CheckCircle, XCircle, PhoneForwarded, Activity, Star, Mic, FileText, DollarSign } from 'lucide-react';
import { cn } from '@/lib/utils';

type CallStatus = 'answered' | 'missed' | 'forwarded';

interface Call {
  id: string;
  callerNumber: string;
  calledNumber: string;
  duration: string;
  status: CallStatus;
  time: string;
  cost: string;
  isLead: boolean;
  agentName: string;
  hasRecording: boolean;
  hasTranscript: boolean;
}

interface RecentCallsTableProps {
  calls: Call[];
}

const statusConfig: Record<CallStatus, { label: string; icon: React.ReactNode; className: string }> = {
  answered: {
    label: 'Answered',
    icon: <CheckCircle className="w-4 h-4" />,
    className: 'status-answered',
  },
  missed: {
    label: 'Missed',
    icon: <XCircle className="w-4 h-4" />,
    className: 'status-missed',
  },
  forwarded: {
    label: 'Forwarded',
    icon: <PhoneForwarded className="w-4 h-4" />,
    className: 'status-voicemail',
  },
};

const RecentCallsTable = ({ calls }: RecentCallsTableProps) => {
  return (
    <div 
      className="glass-card overflow-hidden opacity-0 animate-fade-in-up" 
      style={{ animationDelay: '500ms', animationFillMode: 'forwards' }}
    >
      <div className="p-6 border-b border-border/50 flex items-center justify-between">
        <h2 className="text-2xl font-bold text-foreground flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-primary/20">
            <Activity className="w-6 h-6 text-primary" />
          </div>
          <span>Recent Calls</span>
        </h2>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <div className="w-2 h-2 rounded-full bg-success animate-pulse" />
            <span>Live updating</span>
          </div>
          <span className="text-xs text-muted-foreground px-2 py-1 rounded-full bg-muted/50">
            Showing last {calls.length} calls
          </span>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-border/30 bg-muted/30">
              <th className="px-6 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Caller
              </th>
              <th className="px-4 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Agent
              </th>
              <th className="px-4 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Duration
              </th>
              <th className="px-4 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Status
              </th>
              <th className="px-4 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Cost
              </th>
              <th className="px-4 py-4 text-center text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Details
              </th>
              <th className="px-4 py-4 text-left text-xs font-bold text-muted-foreground uppercase tracking-wider">
                Time
              </th>
            </tr>
          </thead>
          <tbody>
            {calls.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-6 py-16 text-center">
                  <div className="flex flex-col items-center gap-4">
                    <div className="w-20 h-20 rounded-full bg-muted/50 flex items-center justify-center">
                      <Phone className="w-10 h-10 text-muted-foreground/30" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-foreground">No recent calls</p>
                      <p className="text-sm text-muted-foreground">Calls will appear here once received</p>
                    </div>
                  </div>
                </td>
              </tr>
            ) : (
              calls.map((call) => {
                const status = statusConfig[call.status];
                return (
                  <tr 
                    key={call.id}
                    className="border-b border-border/20 hover:bg-muted/20 transition-all duration-200 group cursor-pointer"
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-primary/15 flex items-center justify-center group-hover:scale-105 transition-transform duration-300 flex-shrink-0">
                          <Phone className="w-4 h-4 text-primary" />
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="font-bold text-foreground font-mono text-sm">{call.callerNumber}</span>
                            {call.isLead && (
                              <Star className="w-3.5 h-3.5 text-warning fill-warning flex-shrink-0" />
                            )}
                          </div>
                          <span className="text-xs text-muted-foreground">{call.calledNumber}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className="text-sm text-muted-foreground truncate block max-w-[120px]" title={call.agentName}>
                        {call.agentName}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1.5 text-muted-foreground">
                        <Clock className="w-3.5 h-3.5 flex-shrink-0" />
                        <span className="font-mono font-medium text-sm">{call.duration}</span>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <span className={cn("status-badge inline-flex items-center gap-1.5 text-xs", status.className)}>
                        {status.icon}
                        {status.label}
                      </span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center gap-1 text-muted-foreground">
                        <DollarSign className="w-3.5 h-3.5 flex-shrink-0" />
                        <span className="font-mono text-sm">{call.cost}</span>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex items-center justify-center gap-2">
                        {call.hasRecording && (
                          <div className="w-6 h-6 rounded-full bg-primary/15 flex items-center justify-center" title="Has recording">
                            <Mic className="w-3 h-3 text-primary" />
                          </div>
                        )}
                        {call.hasTranscript && (
                          <div className="w-6 h-6 rounded-full bg-success/15 flex items-center justify-center" title="Has transcript">
                            <FileText className="w-3 h-3 text-success" />
                          </div>
                        )}
                        {!call.hasRecording && !call.hasTranscript && (
                          <span className="text-xs text-muted-foreground">-</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-4 text-muted-foreground font-medium text-sm whitespace-nowrap">
                      {call.time}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RecentCallsTable;
