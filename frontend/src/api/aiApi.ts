import axiosClient from './axiosClient';

export interface AIChatResponse {
  response: string;
  sessionId: string;
}

type UnknownRecord = Record<string, unknown>;

const isRecord = (value: unknown): value is UnknownRecord =>
  typeof value === 'object' && value !== null;

export const sendAIChatMessage = async (
  message: string,
  sessionId: string,
): Promise<AIChatResponse> => {
  return (await axiosClient.post('/ai/chat', { message, sessionId })) as unknown as AIChatResponse;
};

export const getAIChatErrorMessage = (error: unknown): string => {
  const errorRecord = isRecord(error) ? error : undefined;
  const response = isRecord(errorRecord?.response) ? errorRecord.response : undefined;
  const responseData = isRecord(response?.data) ? response.data : undefined;
  const payload = responseData ?? errorRecord;
  const status = typeof response?.status === 'number' ? response.status : undefined;
  const message = typeof payload?.message === 'string' ? payload.message.toLowerCase() : '';

  if (status === 429 || message.includes('nhiều yêu cầu')) {
    return 'Trợ lý AI đang nhận nhiều yêu cầu. Vui lòng thử lại sau ít phút.';
  }

  if (status === 502 || status === 503 || message.includes('mô hình ai') || message.includes('gemini')) {
    return 'Trợ lý AI đang tạm thời chưa sẵn sàng. Vui lòng thử lại sau.';
  }

  if (message.includes('network') || message.includes('kết nối')) {
    return 'Không thể kết nối đến trợ lý AI. Hãy kiểm tra mạng rồi thử lại.';
  }

  return 'Trợ lý AI chưa thể phản hồi lúc này. Vui lòng thử lại sau.';
};
