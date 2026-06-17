package com.lab.model;

import java.sql.Time;

public class Schedule {
    private int id;
    private int roomId;
    private String roomName; // For displaying in the table
    private int dayOfWeek;
    private Time startTime;
    private Time endTime;
    private String subjectInfo;
    private int tahun;

    // Empty Constructor
    public Schedule() {}

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    
    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }
    
    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }
    
    public int getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(int dayOfWeek) { this.dayOfWeek = dayOfWeek; }
    
    public Time getStartTime() { return startTime; }
    public void setStartTime(Time startTime) { this.startTime = startTime; }
    
    public Time getEndTime() { return endTime; }
    public void setEndTime(Time endTime) { this.endTime = endTime; }
    
    public String getSubjectInfo() { return subjectInfo; }
    public void setSubjectInfo(String subjectInfo) { this.subjectInfo = subjectInfo; }
    
    public int getTahun() { return tahun; }
    public void setTahun(int tahun) { this.tahun = tahun; }
}