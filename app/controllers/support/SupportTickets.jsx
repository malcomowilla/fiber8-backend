// src/components/support/SupportTickets.jsx
import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import toast, { Toaster } from 'react-hot-toast';
import {
  LifeBuoy, Plus, X, Clock, CheckCircle2, AlertTriangle,
  MessageSquareWarning, CreditCard, Wifi, HelpCircle, Send
} from 'lucide-react';

const CATEGORY_META = {
  system:  { label: 'System Issue',  icon: MessageSquareWarning },
  payment: { label: 'Payment Issue', icon: CreditCard },
  network: { label: 'Network Issue', icon: Wifi },
  other:   { label: 'Other',         icon: HelpCircle },
};

const PRIORITY_STYLES = {
  low:    'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300',
  medium: 'bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-400',
  high:   'bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400',
  urgent: 'bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-400',
};

const STATUS_STYLES = {
  open:        'bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-400',
  in_progress: 'bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400',
  resolved:    'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400',
  closed:      'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400',
};

const StatusBadge = ({ status }) => (
  <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${STATUS_STYLES[status] || STATUS_STYLES.open}`}>
    {status === 'resolved' && <CheckCircle2 size={12} />}
    {status === 'open' && <Clock size={12} />}
    {status.replace('_', ' ')}
  </span>
);

const PriorityBadge = ({ priority }) => (
  <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold capitalize ${PRIORITY_STYLES[priority] || PRIORITY_STYLES.medium}`}>
    {priority}
  </span>
);

const NewTicketModal = ({ open, onClose, onCreated }) => {
  const [form, setForm] = useState({ subject: '', description: '', category: 'system', priority: 'medium' });
  const [submitting, setSubmitting] = useState(false);
  const subdomain = window.location.hostname.split('.')[0];

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.subject.trim() || !form.description.trim()) {
      toast.error('Please fill in the subject and description');
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch('/api/client_support_tickets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Subdomain': subdomain },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      if (res.ok) {
        toast.success('Ticket submitted — our team has been notified');
        onCreated(data);
        setForm({ subject: '', description: '', category: 'system', priority: 'medium' });
        onClose();
      } else {
        toast.error(data.errors?.[0] || 'Could not submit ticket');
      }
    } catch {
      toast.error('Something went wrong. Please try again');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 backdrop-blur-sm px-4 font-sans"
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 10 }}
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-lg bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 max-h-[90vh] overflow-y-auto"
          >
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center">
                  <LifeBuoy size={18} className="text-indigo-600 dark:text-indigo-400" />
                </div>
                <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">Raise a support ticket</h3>
              </div>
              <button onClick={onClose} className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 mb-1.5 uppercase tracking-wide">
                  Category
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {Object.entries(CATEGORY_META).map(([key, { label, icon: Icon }]) => (
                    <button
                      type="button"
                      key={key}
                      onClick={() => setForm((f) => ({ ...f, category: key }))}
                      className={`flex items-center gap-2 px-3 py-2.5 rounded-xl border text-sm font-medium transition-colors
                        ${form.category === key
                          ? 'border-indigo-400 bg-indigo-50 text-indigo-700 dark:border-indigo-500 dark:bg-indigo-500/10 dark:text-indigo-400'
                          : 'border-slate-200 text-slate-600 hover:bg-slate-50 dark:border-slate-800 dark:text-slate-400 dark:hover:bg-slate-800/60'}`}
                    >
                      <Icon size={15} />
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 mb-1.5 uppercase tracking-wide">
                  Priority
                </label>
                <div className="flex gap-2">
                  {['low', 'medium', 'high', 'urgent'].map((p) => (
                    <button
                      type="button"
                      key={p}
                      onClick={() => setForm((f) => ({ ...f, priority: p }))}
                      className={`flex-1 px-3 py-2 rounded-xl border text-xs font-semibold capitalize transition-colors
                        ${form.priority === p
                          ? 'border-indigo-400 bg-indigo-50 text-indigo-700 dark:border-indigo-500 dark:bg-indigo-500/10 dark:text-indigo-400'
                          : 'border-slate-200 text-slate-500 hover:bg-slate-50 dark:border-slate-800 dark:text-slate-400 dark:hover:bg-slate-800/60'}`}
                    >
                      {p}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 mb-1.5 uppercase tracking-wide">
                  Subject
                </label>
                <input
                  type="text"
                  value={form.subject}
                  onChange={(e) => setForm((f) => ({ ...f, subject: e.target.value }))}
                  placeholder="Brief summary of the issue"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-800/60
                    px-3.5 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400
                    focus:outline-none focus:ring-2 focus:ring-indigo-400 dark:focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 mb-1.5 uppercase tracking-wide">
                  Description
                </label>
                <textarea
                  rows={4}
                  value={form.description}
                  onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                  placeholder="Describe the issue in detail — what happened, when, and any error messages"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-800/60
                    px-3.5 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 resize-none
                    focus:outline-none focus:ring-2 focus:ring-indigo-400 dark:focus:ring-indigo-500"
                />
              </div>

              <button
                type="submit"
                disabled={submitting}
                className="w-full flex items-center justify-center gap-2 rounded-xl bg-indigo-600 hover:bg-indigo-700
                  disabled:opacity-60 text-white text-sm font-semibold py-2.5 transition-colors"
              >
                <Send size={15} />
                {submitting ? 'Submitting…' : 'Submit ticket'}
              </button>
            </form>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

const SupportTickets = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [filter, setFilter] = useState('all');

  const subdomain = window.location.hostname.split('.')[0];

  const fetchTickets = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/client_support_tickets', {
        headers: { 'X-Subdomain': subdomain },
      });
      if (res.ok) setTickets(await res.json());
    } catch {
      toast.error('Could not load tickets');
    } finally {
      setLoading(false);
    }
  }, [subdomain]);

  useEffect(() => { fetchTickets(); }, [fetchTickets]);

  const filtered = filter === 'all' ? tickets : tickets.filter((t) => t.status === filter);

  const counts = {
    all: tickets.length,
    open: tickets.filter((t) => t.status === 'open').length,
    in_progress: tickets.filter((t) => t.status === 'in_progress').length,
    resolved: tickets.filter((t) => t.status === 'resolved').length,
  };

  return (
    <div className="font-sans">
      <Toaster />
      <NewTicketModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onCreated={(ticket) => setTickets((prev) => [ticket, ...prev])}
      />

      <div className="flex items-center justify-between mb-5 gap-3 flex-wrap">
        <div>
          <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-100">Support Tickets</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
            Raise an issue and our team will get back to you
          </p>
        </div>
        <button
          onClick={() => setModalOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium px-4 py-2.5 transition-colors"
        >
          <Plus size={16} />
          New ticket
        </button>
      </div>

      <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-1">
        {[
          { key: 'all', label: 'All' },
          { key: 'open', label: 'Open' },
          { key: 'in_progress', label: 'In progress' },
          { key: 'resolved', label: 'Resolved' },
        ].map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-colors
              ${filter === f.key
                ? 'bg-slate-900 text-white dark:bg-slate-100 dark:text-slate-900'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700'}`}
          >
            {f.label}
            <span className="text-[10px] opacity-70">{counts[f.key] ?? ''}</span>
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {loading ? (
          [1, 2, 3].map((i) => (
            <div key={i} className="h-24 rounded-2xl bg-slate-100 dark:bg-slate-800/60 animate-pulse" />
          ))
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-center rounded-2xl border border-dashed border-slate-200 dark:border-slate-800">
            <LifeBuoy size={32} className="text-slate-300 dark:text-slate-600 mb-3" />
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">No tickets here</p>
            <p className="text-xs text-slate-400 dark:text-slate-500 mt-1">Raise one if you run into an issue</p>
          </div>
        ) : (
          filtered.map((t) => {
            const Icon = CATEGORY_META[t.category]?.icon || HelpCircle;
            return (
              <motion.div
                key={t.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3 min-w-0">
                    <div className="w-9 h-9 shrink-0 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
                      <Icon size={16} className="text-slate-500 dark:text-slate-400" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-slate-900 dark:text-slate-100 truncate">{t.subject}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 line-clamp-2">{t.description}</p>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1.5 shrink-0">
                    <StatusBadge status={t.status} />
                    <PriorityBadge priority={t.priority} />
                  </div>
                </div>
                <div className="flex items-center justify-between mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                  <span className="text-[11px] text-slate-400 dark:text-slate-500">
                    {new Date(t.created_at).toLocaleString()}
                  </span>
                  {t.admin_notes && (
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 italic truncate max-w-[50%]">
                      Note: {t.admin_notes}
                    </span>
                  )}
                </div>
              </motion.div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default SupportTickets;