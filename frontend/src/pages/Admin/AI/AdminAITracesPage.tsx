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

  const getEventTitle = (type: string) => {
    switch (type) {
      case 'PROMPT_COMPILED': return 'Biên dịch lời gọi';
      case 'LLM_RESPONSE': return 'Phản hồi AI';
      case 'TOOL_EXECUTION': return 'Thực thi công cụ';
      default: return 'Sự kiện khác';
    }
  };

  const getEventBadge = (type: string) => {
    switch (type) {
      case 'PROMPT_COMPILED': return 'Lệnh chuẩn bị';
      case 'LLM_RESPONSE': return 'Kết quả AI';
      case 'TOOL_EXECUTION': return 'Công cụ';
      default: return 'Khác';
    }
  };

  const getEventColorClass = (type: string) => {
    switch (type) {
      case 'PROMPT_COMPILED': return 'bg-sky-100 text-sky-700 border-sky-200';
      case 'LLM_RESPONSE': return 'bg-violet-100 text-violet-700 border-violet-200';
      case 'TOOL_EXECUTION': return 'bg-emerald-100 text-emerald-700 border-emerald-200';
      default: return 'bg-slate-100 text-slate-700 border-slate-200';
    }
  };

  const getUserRoleLabel = (role: string) => {
    switch (role.toLowerCase()) {
      case 'admin': return 'Quản trị viên';
      case 'staff': return 'Nhân viên';
      case 'customer': return 'Khách hàng';
      case 'guest': return 'Khách vãng lai';
      default: return role;
    }
  };

  const formatEventSummary = (raw: string) => {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        return `Mảng gồm ${parsed.length} phần tử`;
      }
      if (typeof parsed === 'object' && parsed !== null) {
        const keys = Object.keys(parsed);
        if (keys.length === 0) {
          return 'Không có dữ liệu chi tiết.';
        }
        const previewKeys = keys.slice(0, 3).join(', ');
        return `Dữ liệu gồm các trường: ${previewKeys}${keys.length > 3 ? '...' : ''}`;
      }
      return String(parsed).slice(0, 140);
    } catch {
      return raw.length > 140 ? `${raw.slice(0, 140)}...` : raw;
    }
  };

  const formatJSON = (raw: string) => {
    try {
      return JSON.stringify(JSON.parse(raw), null, 2);
    } catch {
      return raw;
    }
  };

  const truncateSessionId = (sessionId: string) => {
    if (sessionId.length <= 22) return sessionId;
    return `${sessionId.slice(0, 10)}...${sessionId.slice(-8)}`;
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
          <Terminal className="text-indigo-600" /> Lịch sử tương tác AI
        </h1>
        <p className="text-gray-600">Xem lại luồng hội thoại và các bước xử lý của trợ lý AI theo từng phiên.</p>
      </div>

      <div className="bg-white rounded-3xl shadow-[0_20px_60px_-35px_rgba(15,23,42,0.2)] border border-slate-200 overflow-hidden">
        {traces.length > 0 ? traces.map((trace) => (
          <div key={trace.id} className="border-b border-slate-100 last:border-0">
            <div 
              className="px-6 py-5 flex flex-col gap-3 md:flex-row md:items-center md:justify-between cursor-pointer hover:bg-slate-50 transition-colors"
              onClick={() => {
                setExpandedTraceId(expandedTraceId === trace.id ? null : trace.id);
                if (expandedTraceId !== trace.id) setExpandedEventIdx(null);
              }}
            >
              <div className="flex items-center gap-4">
                {expandedTraceId === trace.id ? <ChevronDown className="text-slate-400" /> : <ChevronRight className="text-slate-400" />}
                <div>
                  <div className="text-sm font-semibold text-slate-900">Phiên: {truncateSessionId(trace.sessionId)}</div>
                  <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-slate-500">
                    <span className="rounded-full border border-slate-200 bg-slate-100 px-2 py-1">Vai trò: {getUserRoleLabel(trace.userRole)}</span>
                    <span>{new Date(trace.createdAt).toLocaleString('vi-VN')}</span>
                    <span className="rounded-full border border-slate-200 bg-slate-100 px-2 py-1">ID đầy đủ: {trace.sessionId}</span>
                  </div>
                </div>
              </div>
              <div className="inline-flex items-center gap-2 rounded-full bg-indigo-50 px-3 py-1 text-sm font-semibold text-indigo-700">
                {trace.events.length} sự kiện
              </div>
            </div>

            {expandedTraceId === trace.id && (
              <div className="px-6 pb-6 bg-slate-50/80">
                <div className="relative ml-3 space-y-5 before:absolute before:left-4 before:top-2 before:h-full before:w-px before:bg-indigo-100">
                  {trace.events.map((evt, idx) => (
                    <div key={idx} className="relative pl-12">
                      <div className={`absolute left-0 top-2 flex h-10 w-10 items-center justify-center rounded-full border shadow-sm ${getEventColorClass(evt.eventType)}`}>
                        {getEventIcon(evt.eventType)}
                      </div>
                      <div className="rounded-3xl border border-slate-200 bg-white shadow-sm overflow-hidden">
                        <button
                          type="button"
                          className="w-full px-5 py-4 text-left transition-colors hover:bg-slate-50"
                          onClick={() => setExpandedEventIdx(expandedEventIdx === idx ? null : idx)}
                        >
                          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                            <div>
                              <div className="text-sm font-semibold text-slate-900">{getEventTitle(evt.eventType)}</div>
                              <div className="mt-1 text-sm text-slate-600">{evt.description}</div>
                            </div>
                            <div className="mt-3 flex flex-wrap items-center gap-2 text-xs text-slate-500 sm:mt-0">
                              {evt.latencyMs > 0 && (
                                <span className="inline-flex items-center gap-1 rounded-full bg-yellow-100 px-2 py-1 text-yellow-700">
                                  <Clock className="h-3.5 w-3.5" /> {evt.latencyMs} ms
                                </span>
                              )}
                              <span>{new Date(evt.timestamp).toLocaleTimeString('vi-VN')}</span>
                            </div>
                          </div>
                        </button>

                        {expandedEventIdx === idx && evt.rawData && (
                          <div className="border-t border-slate-200 bg-slate-950 p-4">
                            <div className="mb-3 space-y-2">
                            <div className="flex flex-wrap items-center justify-between gap-3 text-xs uppercase tracking-[0.2em] text-slate-400">
                              <span>Chi tiết sự kiện</span>
                              <span className={`rounded-full border px-2 py-1 text-[10px] ${getEventColorClass(evt.eventType)}`}>
                                {getEventBadge(evt.eventType)}
                              </span>
                            </div>
                            <div className="rounded-2xl bg-slate-900 p-4 text-xs leading-5 text-slate-200">
                              <div className="mb-3 text-slate-300">{formatEventSummary(evt.rawData)}</div>
                              <pre className="max-h-80 overflow-auto whitespace-pre-wrap wrap-break-word font-mono text-[11px]">
                                {formatJSON(evt.rawData)}
                              </pre>
                            </div>
                          </div>
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
          <div className="p-16 text-center text-slate-500">
            Chưa có bản ghi tương tác AI nào.
          </div>
        )}
      </div>
    </div>
  );
};
