package com.lab.dao;

import com.lab.model.Schedule;
import com.lab.util.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ScheduleDAO {

    // CREATE
    public boolean addSchedule(Schedule s) {
        String sql = "INSERT INTO lab_schedules (room_id, day_of_week, start_time, end_time, subject_info, tahun) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, s.getRoomId());
            ps.setInt(2, s.getDayOfWeek());
            ps.setTime(3, s.getStartTime());
            ps.setTime(4, s.getEndTime());
            ps.setString(5, s.getSubjectInfo());
            ps.setInt(6, s.getTahun());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // READ (Get all schedules to display in the table)
    public List<Schedule> getAllSchedules() {
        List<Schedule> list = new ArrayList<>();
        String sql = "SELECT ls.*, lr.name as room_name FROM lab_schedules ls JOIN lab_rooms lr ON ls.room_id = lr.room_id ORDER BY ls.day_of_week ASC, ls.start_time ASC";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Schedule s = new Schedule();
                // FIX: Matches your exact database column "schedule_id"
                s.setId(rs.getInt("schedule_id")); 
                s.setRoomId(rs.getInt("room_id"));
                s.setRoomName(rs.getString("room_name"));
                s.setDayOfWeek(rs.getInt("day_of_week"));
                s.setStartTime(rs.getTime("start_time"));
                s.setEndTime(rs.getTime("end_time"));
                s.setSubjectInfo(rs.getString("subject_info"));
                s.setTahun(rs.getInt("tahun"));
                list.add(s);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // UPDATE
    public boolean updateSchedule(Schedule s) {
        // FIX: WHERE schedule_id=?
        String sql = "UPDATE lab_schedules SET room_id=?, day_of_week=?, start_time=?, end_time=?, subject_info=?, tahun=? WHERE schedule_id=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, s.getRoomId());
            ps.setInt(2, s.getDayOfWeek());
            ps.setTime(3, s.getStartTime());
            ps.setTime(4, s.getEndTime());
            ps.setString(5, s.getSubjectInfo());
            ps.setInt(6, s.getTahun());
            ps.setInt(7, s.getId()); 
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // DELETE
    public boolean deleteSchedule(int id) {
        // FIX: WHERE schedule_id=?
        String sql = "DELETE FROM lab_schedules WHERE schedule_id=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}