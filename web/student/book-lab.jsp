<%@page import="com.lab.model.Booking"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    if (user == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    if (!"student".equalsIgnoreCase(userType) && !"lecturer".equalsIgnoreCase(userType)) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    String displayRole = "lecturer".equalsIgnoreCase(userType) ? "Lecturer" : "Student";
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Book Lab Room</title>
        <link rel="stylesheet" type="text/css" href="<%= ctx%>/style.css?v=20260510-sidebar-brand-fix">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
        <style>
            /*baru add*/
            .lab-grid {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 1.5rem;
            }

            .lab-card {
                background: #ffffff;
                border: 0.5px solid #e2e8f0;
                border-radius: 16px;
                overflow: hidden;
                cursor: pointer;
                transition: all 0.22s ease;
                display: flex;
                flex-direction: column;
            }

            .lab-card:hover {
                border-color: #3b82f6;
                transform: translateY(-4px);
                box-shadow: 0 12px 28px rgba(59, 130, 246, 0.13);
            }

            .lab-card.selected {
                border: 2px solid #2563eb;
                box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.10);
            }

            .lab-card-img-wrap {
                position: relative;
                width: 100%;
                height: 175px;
                overflow: hidden;
                background: #e8f0fe;
                flex-shrink: 0;
            }

            .lab-card-img-wrap img {
                width: 100%;
                height: 100%;
                object-fit: cover;
                object-position: center;
                display: block;
                transition: transform 0.35s ease;
            }

            .lab-card:hover .lab-card-img-wrap img {
                transform: scale(1.05);
            }

            .lab-card-img-overlay {
                position: absolute;
                inset: 0;
                background: linear-gradient(to top, rgba(15, 23, 42, 0.50) 0%, transparent 60%);
                pointer-events: none;
            }

            .lab-card-cap-badge {
                position: absolute;
                top: 10px;
                right: 10px;
                background: rgba(255, 255, 255, 0.88);
                color: #1e40af;
                font-size: 11px;
                font-weight: 600;
                padding: 3px 9px;
                border-radius: 20px;
                backdrop-filter: blur(4px);
                display: flex;
                align-items: center;
                gap: 4px;
            }

            .lab-card-body {
                padding: 0.9rem 1rem 1rem;
                display: flex;
                flex-direction: column;
                gap: 6px;
                flex: 1;
            }

            .lab-card-type-badge {
                display: inline-flex;
                align-items: center;
                gap: 4px;
                background: #eff6ff;
                color: #1d4ed8;
                font-size: 11px;
                font-weight: 500;
                padding: 3px 8px;
                border-radius: 6px;
                width: fit-content;
            }

            .lab-card-type-badge i {
                font-size: 12px;
            }

            .lab-card-facilities {
                display: flex;
                flex-direction: column;
                gap: 4px;
                margin-top: 2px;
            }

            .facility-row {
                display: flex;
                align-items: center;
                gap: 7px;
                font-size: 12px;
                color: #475569;
            }

            .facility-row i {
                font-size: 14px;
                color: #94a3b8;
                flex-shrink: 0;
                width: 16px;
                text-align: center;
            }

            .lab-select-btn {
                margin-top: auto;
                width: 100%;
                padding: 0.6rem;
                background: #3b82f6;
                color: #ffffff;
                border: none;
                border-radius: 10px;
                font-size: 13px;
                font-weight: 600;
                cursor: pointer;
                transition: background 0.2s;
                display: flex;
                align-items: center;
                justify-content: center;
                gap: 6px;
            }

            .lab-select-btn:hover {
                background: #2563eb;
            }

            .lab-card.selected .lab-select-btn {
                background: #1d4ed8;
            }

            .btn-login:hover {
                background: #2563eb;
            }
            /*============================*/
            /* ==baru add== reset button*/
            .reset-btn {
                padding: 0.7rem;
                border: none;
                border-radius: 12px;
                cursor: pointer;
                font-size: 0.85rem;
                transition: all 0.2s;
                background: #e2e8f0;
            }
            /*==========================*/
            .scheduler-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 2rem;
            }

            .schedule-grid {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 0.75rem;
                margin: 1.2rem 0;
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
            }

            .slot.available {
                background: #e2e8f0;
                color: #1e293b;
            }

            .slot.available:hover {
                background: #cbd5e1;
                transform: scale(1.02);
            }

            .slot.selected {
                background: #3b82f6;
                color: white;
            }

            .slot.unavailable {
                background: #fee2e2;
                color: #dc2626;
                cursor: not-allowed;
                opacity: 0.7;
            }

            .form-group {
                margin-bottom: 1.2rem;
            }

            .form-group label {
                display: block;
                font-weight: 500;
                color: #334155;
                margin-bottom: 0.5rem;
                font-size: 0.85rem;
            }

            .form-group input,
            .form-group select {
                width: 100%;
                padding: 0.7rem;
                border: 1px solid #cbd5e1;
                border-radius: 12px;
                font-size: 0.9rem;
                transition: all 0.2s;
                font-family: inherit;
            }

            .form-group input:focus,
            .form-group select:focus {
                outline: none;
                border-color: #3b82f6;
                box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
            }

            .btn-login {
                background: #3b82f6;
                color: white;
                padding: 0.8rem 1.5rem;
                border: none;
                border-radius: 12px;
                font-weight: 600;
                cursor: pointer;
                width: 100%;
                transition: background 0.2s;
                font-size: 0.9rem;
            }

            .btn-login:hover {
                background: #2563eb;
            }
        </style>
    </head>
    <body class="portal-shell">
        <div class="portal-layout">
            <aside class="side-nav">
                <div class="brand-lockup">
                    <span class="sidebar-logo-badge">
                        <img class="sidebar-logo" src="<%= ctx%>/assets/Logo_Rasmi_UMT_sidebar.png" alt="Universiti Malaysia Terengganu logo">
                    </span>
                    <div>
                        <span class="eyebrow">Student Menu</span>
                        <h2>FSKM Lab Booking</h2>
                    </div>
                </div>
                <nav class="nav-links">
                    <a href="<%= ctx%>/user/my-account.jsp">My Account</a>
                    <a href="dashboard.jsp">Dashboard</a>
                    <a class="active" href="book-lab.jsp">Book Lab Room</a>
                    <a href="my-bookings.jsp">My Bookings</a>
                    <a href="view_schedule.jsp">Lab Schedule</a>
                </nav>
                <a class="ghost-btn" href="<%= ctx%>/LogoutServlet">Logout</a>
            </aside>

            <form action="${pageContext.request.contextPath}/BookingServlet" method="post">
                <main class="content-panel">
                    <section class="section-card">
                        <div class="section-heading">
                            <div>
                                <h1>Select a Lab Room</h1>
                            </div>
                        </div>
                        <div class="lab-grid">

                            <article class="lab-card" data-room="Programming Lab I">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/lab1.jpg" alt="Programming Laboratory 1">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 57 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-device-desktop"></i> Programming Lab 1</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>2 units LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>2 units LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-building-broadcast-tower"></i>Smart classroom equipped</span>
                                        <span class="facility-row"><i class="ti ti-volume"></i>Audio Visual System</span>
                                        <span class="facility-row"><i class="ti ti-cpu"></i>HP computers</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="Programming Lab 2">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/lab2.jpg" alt="Programming Laboratory 2">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 57 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-device-desktop"></i> Programming Lab 2</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>2 units LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>2 units LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-building-broadcast-tower"></i>Smart classroom equipped</span>
                                        <span class="facility-row"><i class="ti ti-volume"></i>Audio Visual System</span>
                                        <span class="facility-row"><i class="ti ti-cpu"></i>HP computers</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="Programming Lab 3">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/lab3.jpg" alt="Programming Laboratory 3">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 51 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-device-desktop"></i> Programming Lab 3</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>2 units LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>2 units LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-building-broadcast-tower"></i>Smart classroom equipped</span>
                                        <span class="facility-row"><i class="ti ti-volume"></i>Audio Visual System</span>
                                        <span class="facility-row"><i class="ti ti-cpu"></i>Dell Optilex SF 7020</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="CISCO Networking Standard Laboratory">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labcisco.jpg" alt="CISCO Networking standard Laboratory">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 49 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-network"></i> CISCO Networking Standard Laboratory</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>2 units LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>2 units LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-building-broadcast-tower"></i>Smart classroom equipped</span>
                                        <span class="facility-row"><i class="ti ti-volume"></i>Audio Visual System</span>
                                        <span class="facility-row"><i class="ti ti-cpu"></i>Dell Optilex SF 7020</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="Mobile Computing Lab">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labmobile.png" alt="Mobile Computing Laboratory">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 20 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-device-mobile"></i> Mobile Computing Lab</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>1 unit LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>1 unit LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-headphones"></i>Headset</span>
                                        <span class="facility-row"><i class="ti ti-brand-apple"></i>Mac computers</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="CERMAT Laboratory">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labcermat.jpg" alt="CERMAT Laboratory">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 54 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-device-desktop"></i> CERMAT Lab</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-device-tv"></i>2 units LCD screen</span>
                                        <span class="facility-row"><i class="ti ti-device-projector"></i>2 units LCD Projector</span>
                                        <span class="facility-row"><i class="ti ti-building-broadcast-tower"></i>Smart classroom equipped</span>
                                        <span class="facility-row"><i class="ti ti-volume"></i>Audio Visual System</span>
                                        <span class="facility-row"><i class="ti ti-cpu"></i>Dell SF 7020 computers</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="AL-SAFA Laboratory">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labsafa.jpg" alt="AL-SAFA Laboratory">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 24 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-microscope"></i> AL Safa Lab</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-code"></i>Research Software</span>
                                        <span class="facility-row"><i class="ti ti-armchair"></i>Personal Space</span>
                                        <span class="facility-row"><i class="ti ti-printer"></i>Printer</span>
                                        <span class="facility-row"><i class="ti ti-wifi"></i>WiFi & LAN</span>
                                        <span class="facility-row"><i class="ti ti-plug"></i>2 unit power supply</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="Mathematics & Computer Science Research Laboratory 1">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labresearch1.jpg" alt="Mathematics & Computer Science Research Laboratory 1">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 24 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-math"></i> Mathematics & Computer Science Research Laboratory 1</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-code"></i>Research Software</span>
                                        <span class="facility-row"><i class="ti ti-armchair"></i>Personal Space</span>
                                        <span class="facility-row"><i class="ti ti-printer"></i>Printer</span>
                                        <span class="facility-row"><i class="ti ti-wifi"></i>WiFi & LAN</span>
                                        <span class="facility-row"><i class="ti ti-plug"></i>2 unit power supply</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                            <article class="lab-card" data-room="Mathematics & Computer Science Research Laboratory 2">
                                <div class="lab-card-img-wrap">
                                    <img src="${pageContext.request.contextPath}/assets/labresearch2.jpg" alt="Mathematics & Computer Science Research Laboratory 2">
                                    <div class="lab-card-img-overlay"></div>
                                    <span class="lab-card-cap-badge"><i class="ti ti-users"></i> 24 seats</span>
                                </div>
                                <div class="lab-card-body">
                                    <span class="lab-card-type-badge"><i class="ti ti-math"></i> Mathematics & Computer Science Research Laboratory 2</span>
                                    <div class="lab-card-facilities">
                                        <span class="facility-row"><i class="ti ti-code"></i>Research Software</span>
                                        <span class="facility-row"><i class="ti ti-armchair"></i>Personal Space</span>
                                        <span class="facility-row"><i class="ti ti-printer"></i>Printer</span>
                                        <span class="facility-row"><i class="ti ti-wifi"></i>WiFi & LAN</span>
                                        <span class="facility-row"><i class="ti ti-plug"></i>2 unit power supply</span>
                                    </div>
                                    <button class="lab-select-btn" type="button"> Select this lab</button>
                                </div>
                            </article>

                        </div>
                        <input type="hidden" id="selectedRoom" name="selectedRoom" value="">
                    </section>

                    <section class="scheduler-grid">
                        <article class="section-card">
                            <div class="section-heading">
                                <div>
                                    <h2>Check Availability</h2>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Date</label>
                                    <input type="date" name="dates" id="dates">
                                </div>
                            </div>
                            <div class="schedule-grid" id="time">
                                <button type="button" class="slot" data-time="8:00">08:00</button>
                                <button type="button" class="slot" data-time="9:00">09:00</button>
                                <button type="button" class="slot" data-time="10:00">10:00</button>
                                <button type="button" class="slot" data-time="11:00">11:00</button>
                                <button type="button" class="slot" data-time="12:00">12:00</button>
                                <button type="button" class="slot" data-time="14:00">14:00</button>
                                <button type="button" class="slot" data-time="15:00">15:00</button>
                                <button type="button" class="slot" data-time="16:00">16:00</button>
                                <button type="button" class="slot" data-time="17:00">17:00</button>
                                <button type="button" class="reset-btn" id="resetTime" onclick="resetSelection()">&#x21BA; Reset</button>
                            </div>
                            <input type="hidden" name="startTime">
                            <input type="hidden" name="endTime">
                        </article>

                        <article class="section-card">
                            <div class="section-heading">
                                <div>
                                    <h2>Booking Purpose</h2>
                                </div>
                            </div>
                            <div class="form-group">
                                <label>Purpose</label>
                                <select name="purpose" id="purposeSelect">
                                    <option selected disabled>Select purpose</option>
                                    <option value="event">Event</option>
                                    <option value="class">Class</option>
                                    <option value="practical">Practical</option>
                                    <option value="others">Others</option>
                                </select>
                                <div id="otherPurposeWrapper" style="display: none; margin-top: 10px;">
                                    <textarea
                                        name="other_purpose"
                                        id="otherPurpose"
                                        placeholder="Please state your purpose ..."
                                        rows="3"
                                        style="width: 100%; resize: vertical;"
                                        ></textarea>
                                </div>
                            </div>
                            <button class="btn-login" type="submit">Submit Booking</button>
                        </article>
                    </section>
                </main>
            </form>
            <script src="${pageContext.request.contextPath}/script.js"></script>
        </div>
    </body>
</html>