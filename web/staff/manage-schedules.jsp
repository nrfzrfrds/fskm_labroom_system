<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="com.lab.model.Schedule"%>
<%@page import="com.lab.dao.ScheduleDAO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    
    if (user == null || (!"staff".equalsIgnoreCase(userType) && !"labstaff".equalsIgnoreCase(userType))) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }

    ScheduleDAO dao = new ScheduleDAO();
    List<Schedule> schedules = dao.getAllSchedules();
    SimpleDateFormat timeFmt = new SimpleDateFormat("hh:mm a");
    String[] dayNames = {"", "Ahad", "Isnin", "Selasa", "Rabu", "Khamis", "Jumaat", "Sabtu"};
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Academic Schedules</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510">
    <style>
        /* Interactive Timeslot Grid Styles */
        .schedule-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 0.75rem;
            margin: 0.5rem 0 1.2rem 0;
        }
        .slot {
            padding: 0.7rem;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.2s;
            font-size: 0.85rem;
            background: #e2e8f0;
            color: #1e293b;
        }
        .slot:hover:not(.unavailable) {
            background: #cbd5e1;
            transform: scale(1.02);
        }
        .slot.selected {
            background: #3b82f6;
            color: white;
        }
        .slot.unavailable {
            background: #fee2e2 !important;
            color: #dc2626 !important;
            cursor: not-allowed;
            opacity: 0.7;
            border: 1px solid #fca5a5;
        }
        .reset-btn {
            padding: 0.7rem;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            font-size: 0.85rem;
            transition: all 0.2s;
            background: #e2e8f0;
            color: #1e293b;
            font-weight: 600;
        }
        .reset-btn:hover {
            background: #cbd5e1;
        }
        
        /* Force action buttons to stay side-by-side */
        .schedule-row .action-cell {
            display: flex;
            gap: 8px;
            flex-wrap: nowrap !important; /* This prevents stacking */
            justify-content: flex-start;
        }
        
        .schedule-row .action-cell form {
            margin: 0;
            display: flex;
        }
        
        /* Adjust button sizing slightly so they fit nicely */
        .schedule-row .action-cell .table-btn {
            min-height: 38px;
            padding: 6px 16px;
            font-size: 0.85rem;
            border-radius: 6px;
            white-space: nowrap;
        }
    </style>
</head>
<body class="portal-shell">
    <div class="portal-layout">
        <aside class="side-nav">
            <div class="brand-lockup">
                <span class="sidebar-logo-badge">
                    <img class="sidebar-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT_sidebar.png" alt="UMT logo">
                </span>
                <div>
                <span class="eyebrow">Lab Staff Menu</span>
                <h2>FSKM Lab Booking</h2>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%= ctx %>/user/my-account.jsp">My Account</a>
                <a href="<%= ctx %>/staff/dashboard.jsp">Dashboard</a>
                <a href="<%= ctx %>/staff/view-schedule.jsp">Lab Schedule</a>
                <a class="active" href="<%= ctx %>/staff/manage-schedules.jsp">Manage Classes</a>
                <a href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            
            <% 
                String msg = (String) session.getAttribute("message");
                String err = (String) session.getAttribute("error");
                if (msg != null) { out.print("<div class='alert alert-success'>" + msg + "</div>"); session.removeAttribute("message"); }
                if (err != null) { out.print("<div class='alert alert-error'>" + err + "</div>"); session.removeAttribute("error"); }
            %>

            <section class="section-card" id="formSection">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Academic Timetable</span>
                        <h2 id="formTitle">Add New Class Schedule</h2>
                    </div>
                    <button class="ghost-btn" type="button" onclick="resetForm()" style="margin-top:0;">Reset Form</button>
                </div>
                
                <form action="<%= ctx %>/ScheduleServlet" method="POST" class="stack-form" id="scheduleForm">
                    <input type="hidden" name="action" id="formAction" value="add">
                    <input type="hidden" name="id" id="scheduleId" value="0">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Laboratory Room</label>
                            <select name="roomId" id="roomId" required>
                                <%
                                    try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                                         java.sql.PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM lab_rooms ORDER BY name");
                                         java.sql.ResultSet rs = pstmt.executeQuery()) {
                                        while (rs.next()) {
                                            out.println("<option value='" + rs.getInt("room_id") + "'>" + rs.getString("name") + "</option>");
                                        }
                                    } catch(Exception e){}
                                %>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Day of Week</label>
                            <select name="dayOfWeek" id="dayOfWeek" required>
                                <option value="1">Ahad</option>
                                <option value="2">Isnin</option>
                                <option value="3">Selasa</option>
                                <option value="4">Rabu</option>
                                <option value="5">Khamis</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom: 1.5rem;">
                        <label>Select Time Slot</label>
                        <div class="schedule-grid" id="timeSlots">
                            <button type="button" class="slot" data-time="08:00">08:00</button>
                            <button type="button" class="slot" data-time="09:00">09:00</button>
                            <button type="button" class="slot" data-time="10:00">10:00</button>
                            <button type="button" class="slot" data-time="11:00">11:00</button>
                            <button type="button" class="slot" data-time="12:00">12:00</button>
                            <button type="button" class="slot" data-time="14:00">14:00</button>
                            <button type="button" class="slot" data-time="15:00">15:00</button>
                            <button type="button" class="slot" data-time="16:00">16:00</button>
                            <button type="button" class="slot" data-time="17:00">17:00</button>
                            <button type="button" class="reset-btn" id="resetTime" onclick="resetFormTime()">↺ Reset</button>
                        </div>
                        <input type="hidden" name="startTime" id="startTimeInput">
                        <input type="hidden" name="endTime" id="endTimeInput">
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label>Subject / Class Info</label>
                            <input type="text" name="subjectInfo" id="subjectInfo" placeholder="e.g. CSA3023 - Web App Dev" required>
                        </div>
                        <div class="form-group">
                            <label>Tahun (Year)</label>
                            <select name="tahun" id="tahun" required>
                                <option value="1">Tahun 1</option>
                                <option value="2">Tahun 2</option>
                                <option value="3">Tahun 3</option>
                            </select>
                        </div>
                    </div>
                    
                    <button type="submit" class="primary-action" id="submitBtn">Save Schedule</button>
                </form>
            </section>

            <section class="section-card" style="padding: 0; overflow: hidden;">
                
                <div style="padding: 20px; background: #fbfdff; border-bottom: 1px solid #e5ecf4; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 15px;">
                    <h3 style="margin: 0; color: #243447; font-size: 1.25rem;">Saved Schedules</h3>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <label for="tableRoomFilter" style="font-weight: 700; color: #58677a; font-size: 0.9rem;">Filter by Lab:</label>
                        <select id="tableRoomFilter" onchange="filterTable()" style="padding: 8px 12px; border: 1px solid #d5dfeb; border-radius: 6px; outline: none; font-weight: 600; color: #0b4ea2;">
                            <option value="ALL">All Laboratories</option>
                            <%
                                try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                                     java.sql.PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM lab_rooms ORDER BY name");
                                     java.sql.ResultSet rs = pstmt.executeQuery()) {
                                    while (rs.next()) {
                                        out.println("<option value='" + rs.getInt("room_id") + "'>" + rs.getString("name") + "</option>");
                                    }
                                } catch(Exception e){}
                            %>
                        </select>
                    </div>
                </div>

                <table class="user-table">
                    <thead>
                        <tr>
                            <th>Lab Room</th>
                            <th>Day</th>
                            <th>Time</th>
                            <th>Subject Info</th>
                            <th>Tahun</th>
                            <th style="width: 180px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (schedules != null && !schedules.isEmpty()) { 
                            for (Schedule s : schedules) { 
                                // Format time for the HTML inputs (HH:mm)
                                String inputStart = s.getStartTime().toString().substring(0, 5);
                                String inputEnd = s.getEndTime().toString().substring(0, 5);
                        %>
                        <tr class="schedule-row" data-room-id="<%= s.getRoomId() %>">
                            <td><strong><%= s.getRoomName() %></strong></td>
                            <td><%= dayNames[s.getDayOfWeek()] %></td>
                            <td><%= timeFmt.format(s.getStartTime()) %> - <%= timeFmt.format(s.getEndTime()) %></td>
                            <td><%= s.getSubjectInfo() %></td>
                            <td>Tahun <%= s.getTahun() %></td>
                            <td class="action-cell">
                                <button class="table-btn" type="button" 
                                    onclick="editSchedule(<%= s.getId() %>, <%= s.getRoomId() %>, <%= s.getDayOfWeek() %>, '<%= inputStart %>', '<%= inputEnd %>', '<%= s.getSubjectInfo().replace("'", "\\'") %>', <%= s.getTahun() %>)">
                                    Edit
                                </button>
                                <form action="<%= ctx %>/ScheduleServlet" method="POST" style="display:inline;" onsubmit="return confirm('Delete this class?');">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<%= s.getId() %>">
                                    <button type="submit" class="table-btn table-btn-danger">Delete</button>
                                </form>
                            </td>
                        </tr>
                        <%  } 
                           } else { %>
                           <tr><td colspan="6" style="text-align: center; padding: 20px;">No static classes scheduled yet.</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </section>
        </main>
    </div>

    <script>
        const ctxPath = '<%= request.getContextPath() %>';

        // -- TABLE FILTER LOGIC --
        function filterTable() {
            const selectedRoom = document.getElementById("tableRoomFilter").value;
            const rows = document.querySelectorAll(".schedule-row");

            rows.forEach(row => {
                const rowRoomId = row.getAttribute("data-room-id");
                if (selectedRoom === "ALL" || selectedRoom === rowRoomId) {
                    row.style.display = ""; 
                } else {
                    row.style.display = "none"; 
                }
            });
        }

        // -- INTERACTIVE TIMESLOT LOGIC --
        let schStartSlot = null;
        let schEndSlot = null;
        let unavailableSlots = [];
        let isEditingMode = false;

        function timeToMinutes(t) {
            if (!t) return 0;
            const parts = t.split(':').map(Number);
            return parts[0] * 60 + (parts[1] || 0);
        }

        function checkAvailability() {
            const roomId = document.getElementById('roomId').value;
            const dayOfWeek = document.getElementById('dayOfWeek').value;
            const scheduleId = document.getElementById('scheduleId').value;

            if (!isEditingMode) {
                resetFormTime(); 
            }

            if (roomId && dayOfWeek) {
                const url = ctxPath + '/ScheduleServlet?roomId=' + roomId + '&dayOfWeek=' + dayOfWeek + '&excludeId=' + scheduleId;
                
                fetch(url)
                    .then(res => res.json())
                    .then(data => {
                        unavailableSlots = data;
                        markUnavailableSlots();
                        if (isEditingMode && schStartSlot) updateSelectedButtons();
                    })
                    .catch(err => {
                        console.error("Error fetching slots:", err);
                        alert("Could not load available time slots. Please check your console.");
                    });
            }
        }

        function markUnavailableSlots() {
            document.querySelectorAll('#timeSlots .slot').forEach(btn => {
                btn.classList.remove('unavailable');
                btn.disabled = false;

                const slotMins = timeToMinutes(btn.getAttribute('data-time'));
                const isUnavailable = unavailableSlots.some(sch => {
                    return slotMins >= timeToMinutes(sch.startTime) && slotMins < timeToMinutes(sch.endTime);
                });

                if (isUnavailable) {
                    btn.classList.add('unavailable');
                    btn.disabled = true;
                }
            });
        }

        function updateSelectedButtons() {
            const startInput = document.getElementById('startTimeInput');
            const endInput = document.getElementById('endTimeInput');

            // Map visual slots to hidden form inputs
            if (schStartSlot) {
                startInput.value = schStartSlot + ":00";
                
                // Calculate actual end time (+1 hour from the last selected slot)
                const endH = parseInt((schEndSlot || schStartSlot).split(':')[0]) + 1;
                endInput.value = (endH < 10 ? '0' + endH : endH) + ":00:00";
            } else {
                startInput.value = "";
                endInput.value = "";
            }

            // Visually highlight buttons
            document.querySelectorAll('#timeSlots .slot').forEach(btn => {
                btn.classList.remove('selected');
                const t = timeToMinutes(btn.getAttribute('data-time'));
                const startMins = timeToMinutes(schStartSlot);
                const endMins = schEndSlot ? timeToMinutes(schEndSlot) : startMins;

                if (schStartSlot && t >= startMins && t <= endMins) {
                    btn.classList.add('selected');
                }
            });
        }

        // Attach clicks to the time buttons
        document.querySelectorAll('#timeSlots .slot').forEach(btn => {
            btn.addEventListener('click', () => {
                if (btn.classList.contains('unavailable')) return;
                const clickedTime = btn.getAttribute('data-time');

                if (schStartSlot === null) {
                    schStartSlot = clickedTime;
                    schEndSlot = null;
                } else if (schEndSlot === null) {
                    if (timeToMinutes(clickedTime) > timeToMinutes(schStartSlot)) {
                        schEndSlot = clickedTime;
                    } else {
                        schStartSlot = clickedTime;
                        schEndSlot = null;
                    }
                } else {
                    schStartSlot = clickedTime;
                    schEndSlot = null;
                }

                // Safety check: Prevent highlighting across an unavailable slot
                if (schStartSlot && schEndSlot) {
                    const startMins = timeToMinutes(schStartSlot);
                    const endMins = timeToMinutes(schEndSlot);
                    let conflict = false;
                    document.querySelectorAll('#timeSlots .slot').forEach(b => {
                        const m = timeToMinutes(b.getAttribute('data-time'));
                        if (m >= startMins && m <= endMins && b.classList.contains('unavailable')) conflict = true;
                    });
                    
                    if (conflict) {
                        alert("The selected time range overlaps with an existing class.");
                        resetFormTime();
                        return;
                    }
                }

                updateSelectedButtons();
            });
        });

        // Event listeners for drop-downs
        document.getElementById('roomId').addEventListener('change', checkAvailability);
        document.getElementById('dayOfWeek').addEventListener('change', checkAvailability);

        // Form Submission validation
        document.getElementById('scheduleForm').addEventListener('submit', function(e) {
            const startInput = document.getElementById('startTimeInput').value;
            const endInput = document.getElementById('endTimeInput').value;
            
            if (!startInput || !endInput) {
                e.preventDefault();
                alert("Please select a valid time slot from the grid before saving.");
            }
        });

        // -- FORM ACTIONS --
        function editSchedule(id, roomId, day, start, end, subject, tahun) {
            isEditingMode = true;
            document.getElementById('formTitle').innerText = "Edit Class Schedule";
            document.getElementById('formAction').value = "update";
            document.getElementById('submitBtn').innerText = "Update Schedule";
            
            document.getElementById('scheduleId').value = id;
            document.getElementById('roomId').value = roomId;
            document.getElementById('dayOfWeek').value = day;
            document.getElementById('subjectInfo').value = subject;
            document.getElementById('tahun').value = tahun;
            
            schStartSlot = start;
            let endParts = end.split(':');
            let endHour = parseInt(endParts[0]) - 1; 
            schEndSlot = (endHour < 10 ? '0' + endHour : endHour) + ":00";
            
            if (schStartSlot === schEndSlot) schEndSlot = null;

            checkAvailability(); 
            document.getElementById('formSection').scrollIntoView({ behavior: 'smooth' });
            setTimeout(() => { isEditingMode = false; }, 500); 
        }

        function resetFormTime() {
            schStartSlot = null;
            schEndSlot = null;
            updateSelectedButtons();
        }

        function resetForm() {
            document.getElementById('formTitle').innerText = "Add New Class Schedule";
            document.getElementById('formAction').value = "add";
            document.getElementById('submitBtn').innerText = "Save Schedule";
            document.getElementById('scheduleId').value = "0";
            
            document.getElementById('roomId').selectedIndex = 0;
            document.getElementById('dayOfWeek').selectedIndex = 0;
            document.getElementById('subjectInfo').value = "";
            document.getElementById('tahun').selectedIndex = 0;
            
            resetFormTime();
            unavailableSlots = [];
            markUnavailableSlots();
        }

        window.onload = function() {
            checkAvailability();
        };
    </script>
</body>
</html>