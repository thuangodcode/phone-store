import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

interface MarkdownRendererProps {
  content: string;
}

export const MarkdownRenderer: React.FC<MarkdownRendererProps> = ({ content }) => {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm]}
      components={{
        table: ({ node, ...props }) => (
          <div className="overflow-x-auto my-5 rounded-xl border border-slate-200 shadow-sm bg-white">
            <table className="w-full text-sm text-left text-slate-700" {...props} />
          </div>
        ),
        thead: ({ node, ...props }) => (
          <thead className="text-xs text-slate-600 uppercase bg-slate-100/80 border-b border-slate-200" {...props} />
        ),
        th: ({ node, ...props }) => (
          <th className="px-5 py-3.5 font-bold tracking-wide whitespace-nowrap" {...props} />
        ),
        td: ({ node, ...props }) => (
          <td className="px-5 py-3.5 border-b border-slate-100 last:border-0 align-middle" {...props} />
        ),
        tr: ({ node, ...props }) => (
          <tr className="hover:bg-slate-50/50 transition-colors" {...props} />
        ),
        h1: ({ node, ...props }) => <h1 className="text-xl font-bold mt-6 mb-3 text-slate-800" {...props} />,
        h2: ({ node, ...props }) => <h2 className="text-lg font-bold mt-5 mb-2 text-slate-800" {...props} />,
        h3: ({ node, ...props }) => <h3 className="text-base font-bold mt-4 mb-2 text-slate-800" {...props} />,
        p: ({ node, ...props }) => <p className="mb-3 last:mb-0 leading-relaxed text-slate-700" {...props} />,
        ul: ({ node, ...props }) => <ul className="list-disc pl-5 mb-4 space-y-1.5 text-slate-700" {...props} />,
        ol: ({ node, ...props }) => <ol className="list-decimal pl-5 mb-4 space-y-1.5 text-slate-700" {...props} />,
        li: ({ node, ...props }) => <li className="pl-1" {...props} />,
        strong: ({ node, ...props }) => <strong className="font-semibold text-slate-900" {...props} />,
        a: ({ node, ...props }) => <a className="text-blue-600 font-medium hover:underline hover:text-blue-800 transition-colors" {...props} />,
        blockquote: ({ node, ...props }) => (
          <blockquote className="border-l-4 border-blue-500 pl-4 py-1 my-4 bg-blue-50/50 rounded-r-lg italic text-slate-600" {...props} />
        ),
        code: ({ node, className, children, ...props }) => {
          const match = /language-(\w+)/.exec(className || '');
          const isInline = !match && !String(children).includes('\n');
          return isInline ? (
            <code className="px-1.5 py-0.5 rounded-md bg-slate-100 text-pink-600 font-mono text-[13px] border border-slate-200" {...props}>
              {children}
            </code>
          ) : (
            <div className="my-4 rounded-xl overflow-hidden border border-slate-800 bg-slate-900 shadow-md">
              <div className="px-4 py-2 bg-slate-800 border-b border-slate-700 text-xs font-mono text-slate-400 flex justify-between items-center">
                <span>{match?.[1] || 'code'}</span>
              </div>
              <div className="p-4 overflow-x-auto text-[13px] text-slate-50 font-mono leading-relaxed">
                <code className={className} {...props}>
                  {children}
                </code>
              </div>
            </div>
          );
        },
      }}
    >
      {content}
    </ReactMarkdown>
  );
};
