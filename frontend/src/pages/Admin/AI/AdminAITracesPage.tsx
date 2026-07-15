import React, { useEffect, useState } from 'react';
import axiosClient from '../../../api/axiosClient';
import { Activity, Clock, Terminal, ChevronDown, ChevronRight, Zap } from 'lucide-react';

interface AILogEvent {
  eventType: string;
  description: string;
  rawData: string;
  latencyMs: number;
  timestamp: string;
}

interface AILog {
  id: string;
  sessionId: string;
  userId: string;
  userRole: string;
  createdAt: string;
  events: AILogEvent[];
}

export const AdminAITracesPage: React.FC = () => {
  const [traces, setTraces] = useState<AILog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedTraceId, setExpandedTraceId] = useState<string | null>(null);
  const [expandedEventIdx, setExpandedEventIdx] = useState<number | null>(null);

  useEffect(() => {
    fetchTraces();
  }, []);

  const fetchTraces = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await axiosClient.get('/ai/traces');
      setTraces(Array.isArray(data) ? data : []);
    } catch (error: any) {
      console.error('Failed to fetch AI traces:', error);
      setError(error?.message || 'Không thể tải dữ liệu AI traces.');
    } finally {
      setLoading(false);
    }
  };

  const getEventIcon = (type: string) => {
    switch (type) {
      case 'PROMPT_COMPILED': return <Terminal className="text-blue-500 w-5 h-5" />;
      case 'LLM_RESPONSE': return <Zap className="text-purple-500 w-5 h-5" />;
      case 'TOOL_EXECUTION': return <Activity className="text-green-500 w-5 h-5" />;
      default: return <Clock className="text-gray-500 w-5 h-5" />;
    }
  };

  const formatJSON = (raw: string) => {
    try {
      return JSON.stringify(JSON.parse(raw), null, 2);
    } catch {
      return raw;
    }
  };

  if (loading) {
    return <div className="flex justify-center p-12"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div></div>;
  }

  return (
    <div className="space-y-6">
      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          <strong>Có lỗi:</strong> {error}
        </div>
      )}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <Terminal className="text-indigo-600" /> AI Trace Viewer (Wireshark for AI)
        </h1>
        <p className="text-gray-600">Inspect real-time API traffic, reasoning flow, and tool executions of the AI Agent.</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        {traces.length > 0 ? traces.map((trace) => (
          <div key={trace.id} className="border-b border-gray-100 last:border-0">
            {/* Trace Header */}
            <div 
              className="px-6 py-4 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition-colors"
              onClick={() => setExpandedTraceId(expandedTraceId === trace.id ? null : trace.id)}
            >
              <div className="flex items-center gap-4">
                {expandedTraceId === trace.id ? <ChevronDown className="text-gray-400" /> : <ChevronRight className="text-gray-400" />}
                <div>
                  <div className="font-mono text-sm font-semibold text-gray-800">Session: {trace.sessionId}</div>
                  <div className="text-xs text-gray-500 flex items-center gap-2 mt-1">
                    <span className="bg-gray-100 px-2 py-0.5 rounded text-gray-700">Role: {trace.userRole}</span>
                    <span>•</span>
                    <span>{new Date(trace.createdAt).toLocaleString()}</span>
                  </div>
                </div>
              </div>
              <div className="text-sm font-medium text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full">
                {trace.events.length} Events
              </div>
            </div>

            {/* Trace Timeline (Events) */}
            {expandedTraceId === trace.id && (
              <div className="px-6 pb-6 bg-gray-50/50">
                <div className="relative pl-6 border-l-2 border-indigo-100 space-y-6 mt-4 ml-3">
                  {trace.events.map((evt, idx) => (
                    <div key={idx} className="relative">
                      {/* Event Dot */}
                      <div className="absolute -left-[35px] bg-white border border-gray-200 rounded-full p-1 shadow-sm">
                        {getEventIcon(evt.eventType)}
                      </div>
                      
                      {/* Event Content */}
                      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
                        <div 
                          className="px-4 py-3 bg-gray-50 flex justify-between items-center cursor-pointer hover:bg-gray-100"
                          onClick={() => setExpandedEventIdx(expandedEventIdx === idx ? null : idx)}
                        >
                          <div>
                            <span className="font-bold text-gray-700 text-sm">{evt.eventType}</span>
                            <span className="text-gray-500 text-sm ml-3">{evt.description}</span>
                          </div>
                          <div className="flex items-center gap-4">
                            {evt.latencyMs > 0 && (
                              <span className="text-xs font-mono bg-yellow-100 text-yellow-800 px-2 py-1 rounded flex items-center gap-1">
                                <Clock w-3 h-3 /> {evt.latencyMs}ms
                              </span>
                            )}
                            <span className="text-xs text-gray-400 font-mono">{new Date(evt.timestamp).toLocaleTimeString()}</span>
                          </div>
                        </div>
                        
                        {/* JSON Payload Inspector */}
                        {expandedEventIdx === idx && evt.rawData && (
                          <div className="p-4 bg-[#1e1e1e] border-t border-gray-200 overflow-x-auto">
                            <pre className="text-[#d4d4d4] font-mono text-xs leading-relaxed">
                              {formatJSON(evt.rawData)}
                            </pre>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )) : (
          <div className="p-12 text-center text-gray-500">
            Chưa có lịch sử Trace nào được ghi nhận.
          </div>
        )}
      </div>
    </div>
  );
};
