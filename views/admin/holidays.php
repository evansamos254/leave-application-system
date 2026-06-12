<div class="two-column">
    <section class="panel">
        <div class="panel-heading">
            <div>
                <p class="eyebrow">Calendar</p>
                <h2>Add Public Holiday</h2>
            </div>
        </div>

        <form class="form" method="post" action="<?= e(url('admin/holidays')) ?>">
            <?= csrf_field() ?>
            <label>
                <span>Holiday Name</span>
                <input type="text" name="name" required>
            </label>
            <label>
                <span>Date</span>
                <input type="date" name="holiday_date" required>
            </label>
            <button class="btn btn-primary" type="submit">Save Holiday</button>
        </form>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div>
                <p class="eyebrow">Configured</p>
                <h2>Holiday List</h2>
            </div>
        </div>

        <?php if (!$holidays): ?>
            <p class="muted">No holidays configured yet.</p>
        <?php else: ?>
            <div class="table-wrap">
                <table>
                    <thead>
                    <tr>
                        <th>Name</th>
                        <th>Date</th>
                        <th>Action</th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($holidays as $holiday): ?>
                        <tr>
                            <td><?= e($holiday['name']) ?></td>
                            <td><?= e(format_date($holiday['holiday_date'])) ?></td>
                            <td>
                                <form method="post" action="<?= e(url('admin/holidays/delete')) ?>" class="inline-form confirm-form">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="id" value="<?= (int) $holiday['id'] ?>">
                                    <button class="btn btn-small btn-danger" type="submit">Delete</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </section>
</div>

