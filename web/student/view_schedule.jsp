<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");

    // Session guard — any logged-in user can view
    if (user == null || userType == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }

    boolean isStaff = "staff".equalsIgnoreCase(userType) || "labstaff".equalsIgnoreCase(userType);

    // Determine which sidebar to show based on role
    String sidebarRole = isStaff ? "Lab Staff Menu" : ("lecturer".equalsIgnoreCase(userType) ? "Lecturer Menu" : "Student Menu");
    String dashboardLink = isStaff ? (ctx + "/staff/dashboard.jsp") : (ctx + "/lecturer/dashboard.jsp");
    String scheduleLink  = isStaff ? (ctx + "/staff/view-schedule.jsp") : (ctx + "/lecturer/dashboard.jsp");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lab Schedule – FSKM Lab Booking</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510">
    <style>
        /* ── Page chrome ─────────────────────────────── */
        .timetable-shell {
            display: flex;
            flex-direction: column;
            gap: 1.25rem;
        }

        /* ── Controls bar ────────────────────────────── */
        .cal-controls {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 0.75rem;
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 1rem 1.25rem;
        }
        .cal-controls label {
            font-weight: 700;
            color: #475569;
            font-size: 0.85rem;
            white-space: nowrap;
        }
        .cal-controls select {
            padding: 0.5rem 0.75rem;
            border: 1.5px solid #cbd5e1;
            border-radius: 8px;
            font-size: 0.9rem;
            font-weight: 600;
            color: #1e3a5f;
            background: #f8fafc;
            cursor: pointer;
            outline: none;
            transition: border-color 0.15s;
        }
        .cal-controls select:focus { border-color: #3b82f6; }

        .nav-month-btn {
            padding: 0.5rem 1rem;
            border: 1.5px solid #cbd5e1;
            border-radius: 8px;
            background: #f8fafc;
            font-size: 0.9rem;
            font-weight: 700;
            color: #1e3a5f;
            cursor: pointer;
            transition: background 0.15s, border-color 0.15s;
        }
        .nav-month-btn:hover { background: #e0eeff; border-color: #93c5fd; }

        .month-label {
            font-size: 1.15rem;
            font-weight: 800;
            color: #0f2644;
            min-width: 160px;
            text-align: center;
        }

        /* ── Legend ──────────────────────────────────── */
        .cal-legend {
            display: flex;
            gap: 1.5rem;
            flex-wrap: wrap;
            align-items: center;
            margin-left: auto;
        }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 0.78rem;
            font-weight: 600;
            color: #475569;
        }
        .legend-dot {
            width: 12px; height: 12px;
            border-radius: 3px;
            flex-shrink: 0;
        }
        .dot-schedule  { background: #dbeafe; border: 1.5px solid #93c5fd; }
        .dot-approved  { background: #dcfce7; border: 1.5px solid #86efac; }
        .dot-pending   { background: #fef9c3; border: 1.5px solid #fde047; }
        .dot-today     { background: #eff6ff; border: 2px solid #3b82f6; }

        /* ── Calendar grid ───────────────────────────── */
        .cal-grid-wrap {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            overflow: hidden;
        }
        .cal-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
        }
        .cal-header-cell {
            padding: 0.6rem 0;
            text-align: center;
            font-size: 0.78rem;
            font-weight: 800;
            color: #64748b;
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            letter-spacing: 0.04em;
            text-transform: uppercase;
        }
        .cal-day {
            min-height: 115px;
            border-right: 1px solid #e9eef5;
            border-bottom: 1px solid #e9eef5;
            padding: 0.4rem;
            vertical-align: top;
            position: relative;
            background: #fff;
            transition: background 0.1s;
        }
        .cal-day:nth-child(7n) { border-right: none; }
        .cal-day.other-month {
            background: #f8fafc;
        }
        .cal-day.today {
            background: #eff6ff;
            outline: 2px solid #3b82f6;
            outline-offset: -2px;
            border-radius: 0;
            z-index: 1;
        }
        .day-num {
            font-size: 0.8rem;
            font-weight: 700;
            color: #334155;
            margin-bottom: 3px;
            display: inline-block;
            width: 24px;
            height: 24px;
            line-height: 24px;
            text-align: center;
            border-radius: 50%;
        }
        .today .day-num {
            background: #3b82f6;
            color: #fff;
        }
        .other-month .day-num { color: #adb5c4; }

        /* ── Event pills ─────────────────────────────── */
        .event-pill {
            display: block;
            font-size: 0.68rem;
            font-weight: 600;
            border-radius: 5px;
            padding: 2px 5px;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            cursor: pointer;
            line-height: 1.4;
            transition: filter 0.12s;
        }
        .event-pill:hover { filter: brightness(0.93); }

        .pill-schedule {
            background: #dbeafe;
            color: #1e40af;
            border-left: 3px solid #3b82f6;
        }
        .pill-approved {
            background: #dcfce7;
            color: #166534;
            border-left: 3px solid #22c55e;
        }
        .pill-pending {
            background: #fef9c3;
            color: #713f12;
            border-left: 3px solid #eab308;
        }
        .more-events {
            font-size: 0.67rem;
            color: #64748b;
            font-weight: 600;
            padding: 1px 4px;
            cursor: pointer;
        }
        .more-events:hover { color: #3b82f6; text-decoration: underline; }

        /* ── Loading / empty states ──────────────────── */
        .cal-state {
            text-align: center;
            padding: 3rem 1rem;
            color: #94a3b8;
            font-size: 0.95rem;
            grid-column: 1 / -1;
        }
        .cal-state-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
        .spinner {
            width: 36px; height: 36px;
            border: 4px solid #e2e8f0;
            border-top-color: #3b82f6;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
            margin: 0 auto 0.75rem;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* ── Tooltip / detail popup ───────────────────── */
        .event-popup {
            position: fixed;
            z-index: 9999;
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(15,38,68,0.15);
            padding: 1rem 1.2rem;
            min-width: 220px;
            max-width: 300px;
            pointer-events: none;
            opacity: 0;
            transform: translateY(4px);
            transition: opacity 0.15s, transform 0.15s;
        }
        .event-popup.visible {
            opacity: 1;
            transform: translateY(0);
            pointer-events: auto;
        }
        .popup-title {
            font-weight: 800;
            font-size: 0.9rem;
            color: #0f2644;
            margin-bottom: 0.4rem;
        }
        .popup-row {
            font-size: 0.8rem;
            color: #475569;
            margin-bottom: 0.2rem;
            display: flex;
            gap: 0.4rem;
        }
        .popup-row strong { color: #0f2644; min-width: 52px; }
        .popup-badge {
            display: inline-block;
            font-size: 0.72rem;
            font-weight: 700;
            padding: 1px 7px;
            border-radius: 20px;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }
        .badge-schedule { background: #dbeafe; color: #1d4ed8; }
        .badge-approved { background: #dcfce7; color: #15803d; }
        .badge-pending  { background: #fef9c3; color: #92400e; }
        .popup-close {
            position: absolute;
            top: 8px; right: 10px;
            background: none; border: none;
            font-size: 1.1rem; cursor: pointer;
            color: #94a3b8;
            pointer-events: auto;
        }
    </style>
</head>
<body class="portal-shell">
<div class="portal-layout">

    <!-- ── Sidebar ──────────────────────────────────────────────── -->
    <aside class="side-nav">
        <div class="brand-lockup">
            <span class="sidebar-logo-badge">
                <img class="sidebar-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT_sidebar.png" alt="UMT logo">
            </span>
            <div>
                <span class="eyebrow"><%= sidebarRole %></span>
                <h2>FSKM Lab Booking</h2>
            </div>
        </div>
        <nav class="nav-links">
            <a href="<%= ctx %>/user/my-account.jsp">My Account</a>
            <a href="dashboard.jsp">Dashboard</a>
            <a href="book-lab.jsp">Book Lab Room</a>
            <a href="my-bookings.jsp">My Bookings</a>
            <a href="<%= ctx %>/lecturer/view-schedule.jsp">Lab Schedule</a>  <!-- ADD THIS -->
        </nav>
        <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
    </aside>

    <!-- ── Main content ─────────────────────────────────────────── -->
    <main class="content-panel">
        <div class="timetable-shell">

            <!-- Page heading -->
            <div style="margin-bottom: 0.25rem;">
                <span class="eyebrow">Live Timetable</span>
                <h2 style="margin: 0; color: #0f2644; font-size: 1.5rem;">Lab Schedule Calendar</h2>
                <p style="margin: 0.2rem 0 0; color: #64748b; font-size: 0.88rem;">
                    Select a lab and month to view all classes and bookings.
                    <% if (!isStaff) { %><em>View only.</em><% } %>
                </p>
            </div>

            <!-- Controls row -->
            <div class="cal-controls">
                <label for="labSelect">Lab:</label>
                <select id="labSelect">
                    <option value="">— choose a lab —</option>
                </select>

                <span style="margin-left: 0.5rem;"></span>

                <button class="nav-month-btn" id="prevMonth" title="Previous month">&#8249;</button>
                <span class="month-label" id="monthLabel">— select lab —</span>
                <button class="nav-month-btn" id="nextMonth" title="Next month">&#8250;</button>

                <div class="cal-legend">
                    <span class="legend-item"><span class="legend-dot dot-schedule"></span> Class</span>
                    <span class="legend-item"><span class="legend-dot dot-approved"></span> Approved booking</span>
                    <span class="legend-item"><span class="legend-dot dot-pending"></span> Pending booking</span>
                    <span class="legend-item"><span class="legend-dot dot-today"></span> Today</span>
                </div>
            </div>

            <!-- Calendar grid -->
            <div class="cal-grid-wrap">
                <div class="cal-grid" id="calGrid">
                    <!-- Day-of-week headers -->
                    <div class="cal-header-cell">Sun</div>
                    <div class="cal-header-cell">Mon</div>
                    <div class="cal-header-cell">Tue</div>
                    <div class="cal-header-cell">Wed</div>
                    <div class="cal-header-cell">Thu</div>
                    <div class="cal-header-cell">Fri</div>
                    <div class="cal-header-cell">Sat</div>
                    <!-- Days injected by JS -->
                    <div class="cal-state" id="calPlaceholder">
                        <div class="cal-state-icon">📅</div>
                        <div>Select a lab above to view the timetable.</div>
                    </div>
                </div>
            </div>

        </div><!-- /.timetable-shell -->
    </main>

</div><!-- /.portal-layout -->

<!-- ── Event detail popup ───────────────────────────────────────── -->
<div class="event-popup" id="eventPopup">
    <button class="popup-close" id="popupClose">✕</button>
    <div id="popupContent"></div>
</div>

<script>
(function () {
    'use strict';

    const CTX = '<%= ctx %>';

    // ── State ──────────────────────────────────────────────────────
    let currentYear  = new Date().getFullYear();
    let currentMonth = new Date().getMonth() + 1;   // 1-based
    let currentRoomId = null;
    let timetableData = null;   // { roomName, schedules[], bookings[] }

    const MONTH_NAMES = ['January','February','March','April','May','June',
                         'July','August','September','October','November','December'];

    // day_of_week mapping: DB uses 1=Ahad(Sun), 2=Isnin(Mon) ... 7=Sabtu(Sat)
    // JS Date.getDay(): 0=Sun, 1=Mon, ... 6=Sat
    // So DB day_of_week = JS getDay() + 1 (with 7=Sat → db 7, Sun → db 1)
    function jsDoW_to_dbDoW(jsDay) {
        // jsDay 0=Sun→1, 1=Mon→2, ... 6=Sat→7
        return jsDay + 1;
    }

    // ── DOM refs ───────────────────────────────────────────────────
    const labSelect   = document.getElementById('labSelect');
    const prevBtn     = document.getElementById('prevMonth');
    const nextBtn     = document.getElementById('nextMonth');
    const monthLabel  = document.getElementById('monthLabel');
    const calGrid     = document.getElementById('calGrid');
    const placeholder = document.getElementById('calPlaceholder');
    const popup       = document.getElementById('eventPopup');
    const popupClose  = document.getElementById('popupClose');
    const popupContent= document.getElementById('popupContent');

    // ── Load room list ─────────────────────────────────────────────
    function loadRooms() {
        fetch(CTX + '/TimetableServlet?action=rooms')
            .then(r => r.json())
            .then(rooms => {
                rooms.forEach(room => {
                    const opt = document.createElement('option');
                    opt.value = room.id;
                    opt.textContent = room.name;
                    labSelect.appendChild(opt);
                });
            })
            .catch(() => {
                const opt = document.createElement('option');
                opt.textContent = 'Could not load labs';
                opt.disabled = true;
                labSelect.appendChild(opt);
            });
    }

    // ── Load timetable data for current room + month ───────────────
    function loadTimetable() {
        if (!currentRoomId) return;

        showLoading();
        const url = CTX + '/TimetableServlet?action=data&roomId=' + currentRoomId + '&year=' + currentYear + '&month=' + currentMonth;
        fetch(url)
            .then(r => r.json())
            .then(data => {
                timetableData = data;
                renderCalendar();
            })
            .catch(() => {
                showError();
            });
    }

    // ── Calendar rendering ─────────────────────────────────────────
    function renderCalendar() {
        // Remove old day cells (keep the 7 header cells)
        const headers = Array.from(calGrid.querySelectorAll('.cal-header-cell'));
        calGrid.innerHTML = '';
        headers.forEach(h => calGrid.appendChild(h));

        if (!timetableData) { showPlaceholder(); return; }

        monthLabel.textContent = MONTH_NAMES[currentMonth - 1] + ' ' + currentYear;

        // Build the month grid
        const firstDay = new Date(currentYear, currentMonth - 1, 1).getDay(); // 0=Sun
        const daysInMonth = new Date(currentYear, currentMonth, 0).getDate();
        const daysInPrevMonth = new Date(currentYear, currentMonth - 1, 0).getDate();

        const today = new Date();
        const todayStr = today.getFullYear() + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2,'0');

        // Leading empty cells from previous month
        for (let i = 0; i < firstDay; i++) {
            const day = daysInPrevMonth - firstDay + 1 + i;
            calGrid.appendChild(makeDayCell(day, currentYear, currentMonth - 1 || 12, true, todayStr));
        }

        // This month's cells
        for (let d = 1; d <= daysInMonth; d++) {
            calGrid.appendChild(makeDayCell(d, currentYear, currentMonth, false, todayStr));
        }

        // Trailing cells to fill the last row
        const totalCells = firstDay + daysInMonth;
        const trailing = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7);
        for (let i = 1; i <= trailing; i++) {
            calGrid.appendChild(makeDayCell(i, currentYear, currentMonth + 1 > 12 ? 1 : currentMonth + 1, true, todayStr));
        }
    }

    function makeDayCell(dayNum, cellYear, cellMonth, isOtherMonth, todayStr) {
        const cellDateStr = cellYear + '-' + String(cellMonth).padStart(2,'0') + '-' + String(dayNum).padStart(2,'0');
        const cellDate    = new Date(cellYear, cellMonth - 1, dayNum);
        const jsDoW       = cellDate.getDay();   // 0=Sun … 6=Sat
        const dbDoW       = jsDoW_to_dbDoW(jsDoW);
        const isToday     = (cellDateStr === todayStr);

        const cell = document.createElement('div');
        cell.className = 'cal-day' +
                         (isOtherMonth ? ' other-month' : '') +
                         (isToday      ? ' today'       : '');

        // Day number
        const numEl = document.createElement('span');
        numEl.className = 'day-num';
        numEl.textContent = dayNum;
        cell.appendChild(numEl);

        // Only render events for the displayed month (and other-month cells that share same year/month when wrapping)
        const events = collectEvents(cellDateStr, dbDoW, isOtherMonth, cellYear, cellMonth);

        const MAX_PILLS = 3;
        const visible = events.slice(0, MAX_PILLS);
        const overflow = events.length - MAX_PILLS;

        visible.forEach(ev => {
            const pill = document.createElement('span');
            pill.className = 'event-pill pill-' + ev.type;
            pill.textContent = ev.startTime + ' ' + ev.label;
            pill.title = ev.tooltip;
            pill.addEventListener('click', (e) => showPopup(e, ev));
            cell.appendChild(pill);
        });

        if (overflow > 0) {
            const more = document.createElement('span');
            more.className = 'more-events';
            more.textContent = '+' + overflow + ' more';
            more.addEventListener('click', (e) => showAllEventsPopup(e, events, cellDateStr));
            cell.appendChild(more);
        }

        return cell;
    }

    /**
     * Collect all events (schedules + bookings) for a given calendar cell.
     * isOtherMonth cells: still render if the data covers that month (edge months).
     */
    function collectEvents(dateStr, dbDoW, isOtherMonth, cellYear, cellMonth) {
        if (!timetableData) return [];

        const events = [];

        // ── Recurring schedule entries ──────────────────────────────
        // Only show schedules for cells within the displayed month
        // (other-month cells are greyed-out; we skip schedules there for clarity)
        if (!isOtherMonth) {
            timetableData.schedules
                .filter(s => s.dayOfWeek === dbDoW)
                .forEach(s => {
                    events.push({
                        type: 'schedule',
                        startTime: s.startTime,
                        endTime: s.endTime,
                        label: s.subject,
                        tooltip: s.startTime + '–' + s.endTime + ' | ' + s.subject + ' (Yr ' + s.tahun + ')',
                        detail: {
                            title: s.subject,
                            time: s.startTime + ' – ' + s.endTime,
                            extra: 'Year ' + s.tahun + ' Class',
                            status: 'schedule'
                        }
                    });
                });
        }

        // ── One-off bookings ────────────────────────────────────────
        timetableData.bookings
            .filter(b => b.date === dateStr)
            .forEach(b => {
                events.push({
                    type: b.status,     // 'approved' | 'pending'
                    startTime: b.startTime,
                    endTime: b.endTime,
                    label: b.purpose,
                    tooltip: b.startTime + '–' + b.endTime + ' | ' + b.purpose + ' (' + b.status + ')',
                    detail: {
                        title: b.purpose,
                        time: b.startTime + ' – ' + b.endTime,
                        extra: b.bookerName + ' (' + b.userType + ')',
                        status: b.status
                    }
                });
            });

        // Sort by start time
        events.sort((a, b) => a.startTime.localeCompare(b.startTime));
        return events;
    }

    // ── Popup ──────────────────────────────────────────────────────
    function showPopup(e, ev) {
        e.stopPropagation();
        const d = ev.detail;
        const badgeClass = 'badge-' + (d.status === 'schedule' ? 'schedule' : d.status);
        const badgeLabel = d.status === 'schedule' ? 'Class' : d.status.charAt(0).toUpperCase() + d.status.slice(1);

        popupContent.innerHTML =
            '<div class="popup-title">' + escHtml(d.title) + '</div>' +
            '<div class="popup-row"><strong>Time:</strong> ' + escHtml(d.time) + '</div>' +
            '<div class="popup-row"><strong>Info:</strong> ' + escHtml(d.extra) + '</div>' +
            '<div class="popup-row"><strong>Type:</strong>' +
                '<span class="popup-badge ' + badgeClass + '">' + badgeLabel + '</span>' +
            '</div>' +
            '<div class="popup-row" style="margin-top:0.4rem; color:#94a3b8; font-size:0.72rem;">' + timetableData.roomName + '</div>';
        positionPopup(e);
    }

    function showAllEventsPopup(e, events, dateStr) {
        e.stopPropagation();
        let html = '<div class="popup-title">All events – ' + dateStr + '</div>';
        events.forEach(ev => {
            const d = ev.detail;
            const badgeClass = 'badge-' + (d.status === 'schedule' ? 'schedule' : d.status);
            const badgeLabel = d.status === 'schedule' ? 'Class' : d.status.charAt(0).toUpperCase() + d.status.slice(1);
            html += '<div style="padding:5px 0; border-bottom:1px solid #f1f5f9;">' +
                '<div style="font-weight:700;font-size:0.82rem;color:#0f2644;">' + escHtml(d.title) + '</div>' +
                '<div style="font-size:0.75rem;color:#64748b;">' + escHtml(d.time) + ' · ' + escHtml(d.extra) +
                  '<span class="popup-badge ' + badgeClass + '" style="margin-left:4px;">' + badgeLabel + '</span>' +
                '</div>' +
            '</div>';
        });
        popupContent.innerHTML = html;
        positionPopup(e);
    }

    function positionPopup(e) {
        popup.classList.add('visible');
        const rect = popup.getBoundingClientRect();
        let x = e.clientX + 12;
        let y = e.clientY + 12;
        if (x + 310 > window.innerWidth)  x = e.clientX - 320;
        if (y + rect.height > window.innerHeight) y = e.clientY - rect.height - 8;
        popup.style.left = x + 'px';
        popup.style.top  = y + 'px';
    }

    function hidePopup() {
        popup.classList.remove('visible');
    }

    // ── Utility states ─────────────────────────────────────────────
    function showLoading() {
        monthLabel.textContent = MONTH_NAMES[currentMonth - 1] + ' ' + currentYear;
        const headers = Array.from(calGrid.querySelectorAll('.cal-header-cell'));
        calGrid.innerHTML = '';
        headers.forEach(h => calGrid.appendChild(h));
        const el = document.createElement('div');
        el.className = 'cal-state';
        el.innerHTML = '<div class="spinner"></div><div>Loading timetable…</div>';
        calGrid.appendChild(el);
    }

    function showPlaceholder() {
        const headers = Array.from(calGrid.querySelectorAll('.cal-header-cell'));
        calGrid.innerHTML = '';
        headers.forEach(h => calGrid.appendChild(h));
        const el = document.createElement('div');
        el.className = 'cal-state';
        el.innerHTML = '<div class="cal-state-icon">📅</div><div>Select a lab above to view the timetable.</div>';
        calGrid.appendChild(el);
        monthLabel.textContent = '— select lab —';
    }

    function showError() {
        const headers = Array.from(calGrid.querySelectorAll('.cal-header-cell'));
        calGrid.innerHTML = '';
        headers.forEach(h => calGrid.appendChild(h));
        const el = document.createElement('div');
        el.className = 'cal-state';
        el.innerHTML = '<div class="cal-state-icon">⚠️</div><div>Could not load timetable. Please try again.</div>';
        calGrid.appendChild(el);
    }

    function escHtml(s) {
        if (!s) return '';
        return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    // ── Event listeners ────────────────────────────────────────────
    labSelect.addEventListener('change', () => {
        currentRoomId = labSelect.value || null;
        if (!currentRoomId) { showPlaceholder(); return; }
        loadTimetable();
    });

    prevBtn.addEventListener('click', () => {
        if (!currentRoomId) return;
        currentMonth--;
        if (currentMonth < 1) { currentMonth = 12; currentYear--; }
        loadTimetable();
    });

    nextBtn.addEventListener('click', () => {
        if (!currentRoomId) return;
        currentMonth++;
        if (currentMonth > 12) { currentMonth = 1; currentYear++; }
        loadTimetable();
    });

    popupClose.addEventListener('click', hidePopup);
    document.addEventListener('click', (e) => {
        if (!popup.contains(e.target)) hidePopup();
    });

    // ── Init ───────────────────────────────────────────────────────
    loadRooms();

})();
</script>
</body>
</html>
