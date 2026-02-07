import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  Typography,
  Button,
  TextField,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Save as SaveIcon } from '@mui/icons-material';
import { supabase } from '../../lib/supabase';

interface WeeklyAvailabilityProps {
  scheduleId: string;
}

interface DayAvailability {
  id?: string;
  day_of_week: number;
  is_available: boolean;
  start_time: string;
  end_time: string;
  break_start_time: string | null;
  break_end_time: string | null;
}

const DAYS = [
  { value: 0, label: 'Sunday' },
  { value: 1, label: 'Monday' },
  { value: 2, label: 'Tuesday' },
  { value: 3, label: 'Wednesday' },
  { value: 4, label: 'Thursday' },
  { value: 5, label: 'Friday' },
  { value: 6, label: 'Saturday' },
];

const WeeklyAvailability: React.FC<WeeklyAvailabilityProps> = ({ scheduleId }) => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [availability, setAvailability] = useState<DayAvailability[]>([]);

  useEffect(() => {
    fetchAvailability();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [scheduleId]);

  const fetchAvailability = async () => {
    setLoading(true);
    setError(null);

    try {
      const { data, error: fetchError } = await supabase
        .from('weekly_availability')
        .select('*')
        .eq('schedule_id', scheduleId)
        .order('day_of_week', { ascending: true });

      if (fetchError) throw fetchError;

      // Initialize all days if not present
      const daysData: DayAvailability[] = DAYS.map((day) => {
        const existing = data?.find((d: any) => d.day_of_week === day.value);
        return existing || {
          day_of_week: day.value,
          is_available: false,
          start_time: '09:00',
          end_time: '17:00',
          break_start_time: null,
          break_end_time: null,
        };
      });

      setAvailability(daysData);
    } catch (err: any) {
      console.error('Error fetching availability:', err);
      setError(err.message || 'Failed to load availability');
    } finally {
      setLoading(false);
    }
  };

  const handleDayChange = (dayIndex: number, field: keyof DayAvailability, value: any) => {
    setAvailability((prev) =>
      prev.map((day, idx) => (idx === dayIndex ? { ...day, [field]: value } : day))
    );
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      for (const day of availability) {
        if (day.id) {
          // Update existing
          const { error: updateError } = await supabase
            .from('weekly_availability')
            .update({
              is_available: day.is_available,
              start_time: day.start_time,
              end_time: day.end_time,
              break_start_time: day.break_start_time || null,
              break_end_time: day.break_end_time || null,
            })
            .eq('id', day.id);

          if (updateError) throw updateError;
        } else {
          // Insert new
          const { error: insertError } = await supabase.from('weekly_availability').insert({
            schedule_id: scheduleId,
            day_of_week: day.day_of_week,
            is_available: day.is_available,
            start_time: day.start_time,
            end_time: day.end_time,
            break_start_time: day.break_start_time || null,
            break_end_time: day.break_end_time || null,
          });

          if (insertError) throw insertError;
        }
      }

      setSuccess('Weekly availability saved successfully!');
      setTimeout(() => setSuccess(null), 3000);
      fetchAvailability();
    } catch (err: any) {
      console.error('Error saving availability:', err);
      setError(err.message || 'Failed to save availability');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" p={3}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h6">Weekly Availability Template</Typography>
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={handleSave}
          disabled={saving}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Day</TableCell>
                <TableCell>Available</TableCell>
                <TableCell>Start Time</TableCell>
                <TableCell>End Time</TableCell>
                <TableCell>Break Start</TableCell>
                <TableCell>Break End</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {availability.map((day, index) => {
                const dayInfo = DAYS.find((d) => d.value === day.day_of_week);
                return (
                  <TableRow key={day.day_of_week}>
                    <TableCell>
                      <Typography fontWeight={600}>{dayInfo?.label}</Typography>
                    </TableCell>
                    <TableCell>
                      <Switch
                        checked={day.is_available}
                        onChange={(e) => handleDayChange(index, 'is_available', e.target.checked)}
                      />
                    </TableCell>
                    <TableCell>
                      <TextField
                        type="time"
                        value={day.start_time}
                        onChange={(e) => handleDayChange(index, 'start_time', e.target.value)}
                        disabled={!day.is_available}
                        size="small"
                        sx={{ width: 120 }}
                      />
                    </TableCell>
                    <TableCell>
                      <TextField
                        type="time"
                        value={day.end_time}
                        onChange={(e) => handleDayChange(index, 'end_time', e.target.value)}
                        disabled={!day.is_available}
                        size="small"
                        sx={{ width: 120 }}
                      />
                    </TableCell>
                    <TableCell>
                      <TextField
                        type="time"
                        value={day.break_start_time || ''}
                        onChange={(e) => handleDayChange(index, 'break_start_time', e.target.value || null)}
                        disabled={!day.is_available}
                        size="small"
                        sx={{ width: 120 }}
                        placeholder="Optional"
                      />
                    </TableCell>
                    <TableCell>
                      <TextField
                        type="time"
                        value={day.break_end_time || ''}
                        onChange={(e) => handleDayChange(index, 'break_end_time', e.target.value || null)}
                        disabled={!day.is_available || !day.break_start_time}
                        size="small"
                        sx={{ width: 120 }}
                        placeholder="Optional"
                      />
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>
    </Box>
  );
};

export default WeeklyAvailability;
